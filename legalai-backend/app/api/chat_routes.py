from flask import Blueprint, request, jsonify, g, current_app
from werkzeug.exceptions import BadRequest, Forbidden, NotFound
from ._auth_guard import require_auth, safe_mode_on
from ..services.rag_service import RAGService
from ..services.llm_service import LLMService
from ..services import llm_settings_service as llm_settings
from ..models.chat import ChatMessage, ChatConversation
from ..models.lawyer import Lawyer
from ..extensions import db
from ..extensions import limiter
from ..tasks.evaluation_tasks import log_rag_evaluation_async
from ..tasks.chat_tasks import process_chat_async
from ..services.rag_evaluation_service import RAGEvaluationService
from ..utils.http_cache import etag_response
from sqlalchemy import func
from sqlalchemy.orm import aliased
import time

bp = Blueprint("chat", __name__)

DISCLAIMER_BY_LANG = {
    "en": (
        "Note: This information is provided only to explain your legal rights. "
        "If you want to take legal action, please contact a lawyer from our provided list "
        "or consult a lawyer in person. For urgent help, use the Helpline."
    ),
    "ur": (
        "نوٹ: یہ معلومات صرف آپ کے قانونی حقوق کی وضاحت کے لیے فراہم کی جاتی ہیں۔ "
        "اگر آپ قانونی کارروائی کرنا چاہتے ہیں تو براہِ کرم ہماری فراہم کردہ فہرست میں سے کسی وکیل سے رابطہ کریں "
        "یا ذاتی طور پر کسی وکیل سے مشورہ کریں۔ فوری مدد کے لیے ہیلپ لائن استعمال کریں۔"
    ),
}

def _infer_lawyer_category(question: str, topic: str | None) -> str | None:
    text = f"{topic or ''} {question or ''}".lower()
    rules = [
        (["divorce", "khula", "talaq"], "Divorce / Khula"),
        (["custody", "guardian", "guardianship"], "Child Custody & Guardianship"),
        (["inheritance", "succession", "will", "probate"], "Inheritance / Succession"),
        (["cyber", "online", "social media", "blackmail"], "Cyber Crime"),
        (["workplace", "employment", "labour", "termination", "salary", "harassment at work"], "Labour & Employment"),
        (["property", "land", "tenant", "rent", "eviction", "real estate"], "Property Law"),
        (["bail"], "Bail Matters"),
        (["criminal", "fir", "police", "assault", "rape", "kidnap", "abduction"], "Criminal Law"),
        (["family", "marriage", "nikah", "domestic", "dowry"], "Family Law"),
        (["human rights", "rights violation"], "Human Rights"),
    ]
    for keys, category in rules:
        if any(k in text for k in keys):
            return category
    return None

def _suggest_lawyers(question: str, topic: str | None, limit: int = 3) -> list[dict]:
    category = _infer_lawyer_category(question, topic)
    if not category:
        return []
    rows = (
        Lawyer.query
        .filter_by(category=category, is_active=True)
        .limit(limit)
        .all()
    )
    return [
        {
            "id": l.id,
            "name": l.full_name,
            "email": l.email,
            "phone": l.phone,
            "category": l.category,
            "profilePicturePath": l.profile_picture_path,
        }
        for l in rows
    ]

def _summarize_title(question: str, max_len: int = 50) -> str:
    q = " ".join((question or "").split())
    if len(q) <= max_len:
        return q or "Chat"
    cut = q[:max_len].rsplit(" ", 1)[0]
    return cut if cut else q[:max_len]

def _get_conversation_or_404(cid: int, user_id: int) -> ChatConversation:
    conv = ChatConversation.query.get(cid)
    if not conv:
        raise NotFound("Conversation not found")
    if conv.user_id != user_id:
        raise Forbidden("Not yours")
    return conv

def _recent_conversation_messages(cid: int, limit: int = 10) -> list[dict]:
    """
    Return last N messages (chronological) from this conversation only.
    This provides true 'resume chat' memory without leaking other chats.
    """
    rows = (
        ChatMessage.query
        .filter_by(conversation_id=cid, user_id=g.user.id)
        .order_by(ChatMessage.created_at.desc())
        .limit(limit)
        .all()
    )
    rows = list(reversed(rows))
    return [{"role": r.role, "content": r.content} for r in rows]

def _detect_emergency_fast(q: str) -> bool:
    ql = (q or "").lower()
    hints = [
        "kill", "murder", "suicide", "self harm", "self-harm", "i will die",
        "threaten to kill", "threat to kill", "he will kill me", "she will kill me",
        "rape", "kidnap", "abduct",
        "قتل", "خودکشی", "جان سے مار", "مار دوں گا", "مار دوں گی", "ماردے", "مر جاؤں",
        "زیادتی", "اغوا"
    ]
    return any(h in ql for h in hints)

def _log_rag_eval(**kwargs):
    """
    Log RAG evaluation with async by default.
    In DEBUG or when async fails, fall back to sync to keep metrics realtime.
    """
    force_sync = current_app.config.get("RAG_LOG_SYNC", False) or current_app.config.get("DEBUG", False)
    if force_sync:
        RAGEvaluationService.log_evaluation(**kwargs)
        return
    try:
        log_rag_evaluation_async.delay(**kwargs)
    except Exception as e:
        current_app.logger.warning("Failed to queue evaluation task: %s", str(e))
        try:
            RAGEvaluationService.log_evaluation(**kwargs)
        except Exception as sync_err:
            current_app.logger.warning("Failed to sync log evaluation: %s", str(sync_err))

@bp.post("/transcribe")
@require_auth()
@limiter.limit("30 per minute")
def transcribe_audio():
    file = request.files.get("file")
    if not file:
        raise BadRequest("Audio file required")
    if not file.filename:
        raise BadRequest("Audio filename required")

    raw_lang = (request.form.get("language") or "").strip().lower()
    language = raw_lang if raw_lang in {"en", "ur"} else None
    provider = (request.form.get("provider") or "").strip().lower()
    model = (request.form.get("model") or "").strip()
    if not provider:
        provider = llm_settings.voice_provider_for(g.user)
    if not model:
        model = llm_settings.voice_model_for(g.user) or ""
    if provider and provider not in {"auto", "openai", "openrouter", "groq"}:
        raise BadRequest("Invalid provider")

    file_bytes = file.read()
    if not file_bytes:
        raise BadRequest("Audio file is empty")

    max_mb = int(current_app.config.get("MAX_UPLOAD_MB", 30))
    if len(file_bytes) > max_mb * 1024 * 1024:
        raise BadRequest(f"Audio file too large (max {max_mb}MB)")

    user_voice_keys = llm_settings.build_voice_keys(g.user)
    openai_key = request.headers.get("X-OpenAI-Key") or user_voice_keys.get("openai")
    openrouter_key = request.headers.get("X-OpenRouter-Key") or user_voice_keys.get("openrouter")
    groq_key = request.headers.get("X-Groq-Key") or user_voice_keys.get("groq")

    text, used_provider = LLMService.transcribe_audio(
        file_bytes=file_bytes,
        filename=file.filename,
        content_type=file.content_type,
        language=language,
        provider=provider or None,
        model_override=model or None,
        openai_key=openai_key,
        openrouter_key=openrouter_key,
        groq_key=groq_key,
    )

    if not text:
        raise BadRequest("No speech detected. Please try again.")

    return jsonify({"text": text, "provider": used_provider})

@bp.post("/ask")
@require_auth()
def ask():
    data = request.get_json() or {}
    request_start_time = time.perf_counter()

    provider_override = (data.get("provider") or "").strip().lower()
    model_override = (data.get("model") or "").strip()
    if provider_override and provider_override not in {"auto", "openai", "openrouter", "groq", "deepseek", "grok", "anthropic"}:
        raise BadRequest("Invalid provider")

    user_keys = llm_settings.build_api_keys(g.user)
    header_keys = {
        "openai": request.headers.get("X-OpenAI-Key"),
        "openrouter": request.headers.get("X-OpenRouter-Key"),
        "groq": request.headers.get("X-Groq-Key"),
        "deepseek": request.headers.get("X-DeepSeek-Key"),
        "grok": request.headers.get("X-Grok-Key"),
        "anthropic": request.headers.get("X-Anthropic-Key"),
    }
    api_keys = {**user_keys, **{k: v for k, v in header_keys.items() if v}}
    api_keys = {k: v.strip() for k, v in api_keys.items() if v and str(v).strip()}
    if not provider_override or provider_override == "auto":
        provider_override = llm_settings.chat_provider_for(g.user)
    if not model_override:
        model_override = llm_settings.chat_model_for(g.user) or ""

    chat_model_used = model_override or current_app.config.get("CHAT_MODEL")

    has_any_key = False
    for candidate in LLMService._provider_fallbacks(provider_override or current_app.config["CHAT_PROVIDER"]):
        if LLMService._provider_key(candidate, api_keys):
            has_any_key = True
            break
    if not has_any_key:
        raise BadRequest("API key isn't setup.")

    q = (data.get("question") or "").strip()
    if not q:
        raise BadRequest("Question required")
    if len(q) > 2000:
        raise BadRequest("Question too long")

    language_override = data.get("language")
    if language_override is not None:
        lang = str(language_override).strip().lower()
        if lang not in {"en", "ur"}:
            raise BadRequest("Invalid language")
        language = lang
    else:
        language = (getattr(g.user, "language", None) or "en")
    province = getattr(g.user, "province", None)
    conv_id = data.get("conversationId")
    memory_limit = current_app.config.get("CHAT_MEMORY_LIMIT", 10)

    if safe_mode_on():
        if _detect_emergency_fast(q):
            route = {"category": "EMERGENCY", "confidence": 1.0, "topic": "emergency"}
        else:
            route = LLMService.classify_query(
                question=q,
                language=language,
                provider_override=provider_override or None,
                model_override=model_override or None,
                api_keys=api_keys or None,
            )

        category = route.get("category")
        topic = route.get("topic") or "other"

        current_app.logger.info(
            "Chat classify: safe_mode=1 user_id=%s lang=%s category=%s topic=%s conf=%s",
            getattr(g.user, "id", None),
            language,
            category,
            topic,
            route.get("confidence"),
        )

        if category == "GREETING_OR_APP_HELP":
            msg = (
                "Hello! I can help with legal awareness for women in Pakistan (workplace harassment, domestic violence, family matters, cyber harassment). "
                "Please describe your situation and I will guide you."
                if language != "ur"
                else
                "السلام علیکم! میں پاکستان میں خواتین کے لیے قانونی آگاہی میں مدد کر سکتی ہوں (کام کی جگہ ہراسانی، گھریلو تشدد، خاندانی معاملات، سائبر ہراسانی)۔ "
                "براہِ کرم اپنا مسئلہ بتائیں، میں رہنمائی کروں گی۔"
            )
            return jsonify({"answer": msg, "conversationId": None, "contextsUsed": 0})

        if category == "EMERGENCY":
            emergency_msg = LLMService.emergency_response(language=language, province=province)
            total_time_ms = int((time.perf_counter() - request_start_time) * 1000)
            _log_rag_eval(
                user_id=g.user.id,
                conversation_id=None,
                language=language,
                safe_mode=True,
                is_new_conversation=True,
                question=q,
                answer=emergency_msg,
                threshold=None,
                best_distance=None,
                contexts_found=0,
                contexts_used=0,
                in_domain=True,
                decision="EMERGENCY",
                chunk_ids=[],
                embedding_time_ms=0,
                llm_time_ms=0,
                total_time_ms=total_time_ms,
                embedding_model=current_app.config.get("TEXT_EMBEDDING_MODEL") or current_app.config["EMBEDDING_MODEL"],
                embedding_dimension=current_app.config.get("TEXT_EMBEDDING_DIMENSION") or current_app.config.get("EMBEDDING_DIMENSION"),
                chat_model=chat_model_used,
                prompt_messages=None,
                completion_text=emergency_msg,
            )

            return jsonify({"answer": emergency_msg, "conversationId": None, "contextsUsed": 0})

        if category in {"OUT_OF_DOMAIN", "PROMPT_INJECTION_OR_MISUSE"}:
            refusal = (
                "I am an AI legal lawyer assistant. I can only help you with legal awareness. "
                "I'm not able to process this query."
                if language != "ur"
                else
                "میں ایک اے آئی لیگل اسسٹنٹ ہوں۔ میں صرف قانونی آگاہی میں مدد کر سکتی ہوں۔ میں اس سوال پر مدد نہیں کر سکتی۔"
            )
            total_time_ms = int((time.perf_counter() - request_start_time) * 1000)
            _log_rag_eval(
                user_id=g.user.id,
                conversation_id=None,
                language=language,
                safe_mode=True,
                is_new_conversation=True,
                question=q,
                answer=refusal,
                threshold=None,
                best_distance=None,
                contexts_found=0,
                contexts_used=0,
                in_domain=False,
                decision="REFUSE_OUT_OF_DOMAIN",
                chunk_ids=[],
                embedding_time_ms=0,
                llm_time_ms=0,
                total_time_ms=total_time_ms,
                embedding_model=current_app.config.get("TEXT_EMBEDDING_MODEL") or current_app.config["EMBEDDING_MODEL"],
                embedding_dimension=current_app.config.get("TEXT_EMBEDDING_DIMENSION") or current_app.config.get("EMBEDDING_DIMENSION"),
                chat_model=chat_model_used,
                prompt_messages=None,
                completion_text=refusal,
            )

            return jsonify({"answer": refusal, "conversationId": None, "contextsUsed": 0})

        retrieval = RAGService.hybrid_search(q, language=language)
        embedding_time_ms = retrieval["embedding_time_ms"]

        chunk_ids = retrieval["chunk_ids"]
        threshold = retrieval["threshold_used"]
        best_distance = retrieval["best_score"]
        has_verified_sources = retrieval["has_verified_sources"]
        contexts = retrieval["contexts_text"]
        image_contexts = retrieval["contexts_images"]

        llm_start = time.perf_counter()
        use_vlm = bool(image_contexts) or bool(current_app.config.get("VLM_ALWAYS", False))
        if use_vlm:
            answer, prompt_messages, _ = LLMService.chat_legal_awareness_multimodal(
                question=q,
                contexts=contexts,
                images=image_contexts,
                language=language,
                province=province,
                history=[],
                provider_override=provider_override or None,
                model_override=model_override or None,
                api_keys=api_keys or None,
            )
        else:
            answer, prompt_messages, _ = LLMService.chat_legal_awareness(
                question=q,
                contexts=contexts,
                language=language,
                province=province,
                history=[],
                provider_override=provider_override or None,
                model_override=model_override or None,
                api_keys=api_keys or None,
            )
        llm_time_ms = int((time.perf_counter() - llm_start) * 1000)

        total_time_ms = int((time.perf_counter() - request_start_time) * 1000)
        decision = "ANSWER_WITH_SOURCES" if has_verified_sources else "ANSWER_NO_SOURCES"

        _log_rag_eval(
            user_id=g.user.id,
            conversation_id=None,
            language=language,
            safe_mode=True,
            is_new_conversation=True,
            question=q,
            answer=answer,
            threshold=threshold,
            best_distance=best_distance,
            contexts_found=retrieval["contexts_found"],
            contexts_used=retrieval["contexts_used"],
            in_domain=True,
            decision=decision,
            chunk_ids=chunk_ids,
            embedding_time_ms=embedding_time_ms,
            llm_time_ms=llm_time_ms,
            total_time_ms=total_time_ms,
            embedding_model=current_app.config.get("TEXT_EMBEDDING_MODEL") or current_app.config["EMBEDDING_MODEL"],
            embedding_dimension=current_app.config.get("TEXT_EMBEDDING_DIMENSION") or current_app.config.get("EMBEDDING_DIMENSION"),
            chat_model=chat_model_used,
            prompt_messages=prompt_messages,
            completion_text=answer,
        )

        suggestions = _suggest_lawyers(q, topic)
        return jsonify({
            "answer": answer,
            "conversationId": None,
            "contextsUsed": retrieval["contexts_used"],
            "lawyers": suggestions,
        })


    is_new_conversation = conv_id is None

    if conv_id is not None:
        try:
            conv_id = int(conv_id)
        except (TypeError, ValueError):
            raise BadRequest("conversationId must be an integer")
        conv = _get_conversation_or_404(conv_id, g.user.id)
    else:
        conv = None

    def _ensure_conversation() -> int:
        nonlocal conv_id, conv
        if conv_id is None:
            conv = ChatConversation(
                user_id=g.user.id,
                title=_summarize_title(q),
            )
            db.session.add(conv)
            db.session.commit()
            conv_id = conv.id
        return conv_id

    history = [] if conv_id is None else _recent_conversation_messages(conv_id, limit=memory_limit)

    if _detect_emergency_fast(q):
        route = {"category": "EMERGENCY", "confidence": 1.0, "topic": "emergency"}
    else:
        route = LLMService.classify_query(
            question=q,
            language=language,
            provider_override=provider_override or None,
            model_override=model_override or None,
            api_keys=api_keys or None,
        )

    category = route.get("category")
    topic = route.get("topic") or "other"

    current_app.logger.info(
        "Chat classify: safe_mode=0 user_id=%s conv_id=%s lang=%s category=%s topic=%s conf=%s",
        getattr(g.user, "id", None),
        conv_id,
        language,
        category,
        topic,
        route.get("confidence"),
    )

    if category == "GREETING_OR_APP_HELP":
        msg = (
            "Hello! I can help with legal awareness for women in Pakistan (workplace harassment, domestic violence, family matters, cyber harassment). "
            "Please describe your situation and I will guide you."
            if language != "ur"
            else
            "السلام علیکم! میں پاکستان میں خواتین کے لیے قانونی آگاہی میں مدد کر سکتی ہوں (کام کی جگہ ہراسانی، گھریلو تشدد، خاندانی معاملات، سائبر ہراسانی)۔ "
            "براہِ کرم اپنا مسئلہ بتائیں، میں رہنمائی کروں گی۔"
        )

        _ensure_conversation()
        ChatMessage.add_and_trim(
            user_id=g.user.id,
            conversation_id=conv_id,
            role="user",
            content=q,
            max_messages=100,
            commit=False,
        )
        ChatMessage.add_and_trim(
            user_id=g.user.id,
            conversation_id=conv_id,
            role="assistant",
            content=msg,
            max_messages=100,
            commit=False,
        )
        db.session.commit()

        return jsonify({"answer": msg, "conversationId": conv_id, "contextsUsed": 0})

    if category == "EMERGENCY":
        emergency_msg = LLMService.emergency_response(language=language, province=province)

        _ensure_conversation()
        ChatMessage.add_and_trim(
            user_id=g.user.id,
            conversation_id=conv_id,
            role="user",
            content=q,
            max_messages=100,
            commit=False,
        )
        ChatMessage.add_and_trim(
            user_id=g.user.id,
            conversation_id=conv_id,
            role="assistant",
            content=emergency_msg,
            max_messages=100,
            commit=False,
        )
        db.session.commit()

        total_time_ms = int((time.perf_counter() - request_start_time) * 1000)
        _log_rag_eval(
            user_id=g.user.id,
            conversation_id=conv_id,
            language=language,
            safe_mode=False,
            is_new_conversation=is_new_conversation,
            question=q,
            answer=emergency_msg,
            threshold=None,
            best_distance=None,
            contexts_found=0,
            contexts_used=0,
            in_domain=True,
            decision="EMERGENCY",
            chunk_ids=[],
            embedding_time_ms=0,
            llm_time_ms=0,
            total_time_ms=total_time_ms,
            embedding_model=current_app.config.get("TEXT_EMBEDDING_MODEL") or current_app.config["EMBEDDING_MODEL"],
            embedding_dimension=current_app.config.get("TEXT_EMBEDDING_DIMENSION") or current_app.config.get("EMBEDDING_DIMENSION"),
            chat_model=chat_model_used,
            prompt_messages=None,
            completion_text=emergency_msg,
        )

        return jsonify({"answer": emergency_msg, "conversationId": conv_id, "contextsUsed": 0})

    if category in {"OUT_OF_DOMAIN", "PROMPT_INJECTION_OR_MISUSE"}:
        refusal = (
            "I am an AI legal lawyer assistant. I can only help you with legal awareness. "
            "I'm not able to process this query."
            if language != "ur"
            else
            "میں ایک اے آئی لیگل اسسٹنٹ ہوں۔ میں صرف قانونی آگاہی میں مدد کر سکتی ہوں۔ میں اس سوال پر مدد نہیں کر سکتی۔"
        )

        _ensure_conversation()
        ChatMessage.add_and_trim(
            user_id=g.user.id,
            conversation_id=conv_id,
            role="user",
            content=q,
            max_messages=100,
            commit=False,
        )
        ChatMessage.add_and_trim(
            user_id=g.user.id,
            conversation_id=conv_id,
            role="assistant",
            content=refusal,
            max_messages=100,
            commit=False,
        )
        db.session.commit()

        total_time_ms = int((time.perf_counter() - request_start_time) * 1000)
        _log_rag_eval(
            user_id=g.user.id,
            conversation_id=conv_id,
            language=language,
            safe_mode=False,
            is_new_conversation=is_new_conversation,
            question=q,
            answer=refusal,
            threshold=None,
            best_distance=None,
            contexts_found=0,
            contexts_used=0,
            in_domain=False,
            decision="REFUSE_OUT_OF_DOMAIN",
            chunk_ids=[],
            embedding_time_ms=0,
            llm_time_ms=0,
            total_time_ms=total_time_ms,
            embedding_model=current_app.config.get("TEXT_EMBEDDING_MODEL") or current_app.config["EMBEDDING_MODEL"],
            embedding_dimension=current_app.config.get("TEXT_EMBEDDING_DIMENSION") or current_app.config.get("EMBEDDING_DIMENSION"),
            chat_model=chat_model_used,
            prompt_messages=None,
            completion_text=refusal,
        )

        return jsonify({"answer": refusal, "conversationId": conv_id, "contextsUsed": 0})

    _ensure_conversation()
    ChatMessage.add_and_trim(
        user_id=g.user.id,
        conversation_id=conv_id,
        role="user",
        content=q,
        max_messages=100,
        commit=False,
    )
    db.session.commit()

    async_enabled = bool(current_app.config.get("CHAT_ASYNC_ENABLED", False))
    if async_enabled:
        try:
            process_chat_async.delay(
                user_id=g.user.id,
                conversation_id=conv_id,
                question=q,
                language=language,
                province=province,
                memory_limit=memory_limit,
                provider=provider_override or None,
                model=model_override or None,
                api_keys=api_keys or None,
            )
            return jsonify({
                "status": "processing",
                "conversationId": conv_id,
                "contextsUsed": 0,
            }), 202
        except Exception as e:
            current_app.logger.warning("Failed to queue async chat: %s", str(e))

    retrieval = RAGService.hybrid_search(q, language=language)
    embedding_time_ms = retrieval["embedding_time_ms"]

    chunk_ids = retrieval["chunk_ids"]
    threshold = retrieval["threshold_used"]
    best_distance = retrieval["best_score"]
    has_verified_sources = retrieval["has_verified_sources"]
    contexts = retrieval["contexts_text"]
    image_contexts = retrieval["contexts_images"]
    decision = "ANSWER_WITH_SOURCES" if has_verified_sources else "ANSWER_NO_SOURCES"

    llm_start = time.perf_counter()
    use_vlm = bool(image_contexts) or bool(current_app.config.get("VLM_ALWAYS", False))
    if use_vlm:
        answer, prompt_messages, _ = LLMService.chat_legal_awareness_multimodal(
            question=q,
            contexts=contexts,
            images=image_contexts,
            language=language,
            province=province,
            history=history,
            provider_override=provider_override or None,
            model_override=model_override or None,
            api_keys=api_keys or None,
        )
    else:
        answer, prompt_messages, _ = LLMService.chat_legal_awareness(
            question=q,
            contexts=contexts,
            language=language,
            province=province,
            history=history,
            provider_override=provider_override or None,
            model_override=model_override or None,
            api_keys=api_keys or None,
        )
    llm_time_ms = int((time.perf_counter() - llm_start) * 1000)

    ChatMessage.add_and_trim(
        user_id=g.user.id,
        conversation_id=conv_id,
        role="assistant",
        content=answer,
        max_messages=100,
        commit=False,
    )
    db.session.commit()

    total_time_ms = int((time.perf_counter() - request_start_time) * 1000)

    _log_rag_eval(
        user_id=g.user.id,
        conversation_id=conv_id,
        language=language,
        safe_mode=False,
        is_new_conversation=is_new_conversation,
        question=q,
        answer=answer,
        threshold=threshold,
        best_distance=best_distance,
        contexts_found=retrieval["contexts_found"],
        contexts_used=retrieval["contexts_used"],
        in_domain=True,
        decision=decision,
        chunk_ids=chunk_ids,
        embedding_time_ms=embedding_time_ms,
        llm_time_ms=llm_time_ms,
        total_time_ms=total_time_ms,
        embedding_model=current_app.config.get("TEXT_EMBEDDING_MODEL") or current_app.config["EMBEDDING_MODEL"],
        embedding_dimension=current_app.config.get("TEXT_EMBEDDING_DIMENSION") or current_app.config.get("EMBEDDING_DIMENSION"),
        chat_model=chat_model_used,
        prompt_messages=prompt_messages,
        completion_text=answer,
    )

    suggestions = _suggest_lawyers(q, topic)
    return jsonify({
        "answer": answer,
        "conversationId": conv_id,
        "contextsUsed": retrieval["contexts_used"],
        "lawyers": suggestions,
    })

@bp.get("/conversations")
@require_auth()
def list_conversations():
    try:
        page = int(request.args.get("page", 1))
        limit = int(request.args.get("limit", 20))
    except ValueError:
        raise BadRequest("page and limit must be integers")

    page = max(page, 1)
    limit = min(max(limit, 1), 100)

    last_msg_subq = (
        db.session.query(
            ChatMessage.conversation_id.label("conversation_id"),
            func.max(ChatMessage.created_at).label("last_created_at"),
        )
        .filter(ChatMessage.user_id == g.user.id)
        .group_by(ChatMessage.conversation_id)
        .subquery()
    )
    last_msg = aliased(ChatMessage)
    q = (
        db.session.query(ChatConversation, last_msg.content)
        .join(last_msg_subq, last_msg_subq.c.conversation_id == ChatConversation.id)
        .outerjoin(
            last_msg,
            (last_msg.conversation_id == ChatConversation.id)
            & (last_msg.created_at == last_msg_subq.c.last_created_at)
            & (last_msg.user_id == g.user.id),
        )
        .filter(ChatConversation.user_id == g.user.id)
        .order_by(ChatConversation.updated_at.desc())
    )
    rows = q.offset((page - 1) * limit).limit(limit).all()

    result = []
    for c, last_content in rows:
        last_snip = (last_content[:120] + "...") if last_content else ""
        result.append({
            "id": c.id,
            "title": c.title,
            "createdAt": c.created_at.isoformat(),
            "updatedAt": c.updated_at.isoformat(),
            "lastMessageSnippet": last_snip,
        })

    filtered = [item for item in result if (item.get("lastMessageSnippet") or "").strip()]
    payload = {"page": page, "limit": limit, "items": filtered}
    return etag_response(payload)

@bp.get("/conversations/<int:cid>/messages")
@require_auth()
def get_conversation_messages(cid: int):
    conv = _get_conversation_or_404(cid, g.user.id)

    try:
        page = int(request.args.get("page", 1))
        limit = int(request.args.get("limit", 30))
    except ValueError:
        raise BadRequest("page and limit must be integers")

    page = max(page, 1)
    limit = min(max(limit, 1), 100)

    q = (
        ChatMessage.query
        .filter_by(conversation_id=conv.id, user_id=g.user.id)
        .order_by(ChatMessage.created_at.desc())
    )
    msgs_desc = q.offset((page - 1) * limit).limit(limit).all()
    msgs = list(reversed(msgs_desc))

    items = [
        {
            "id": m.id,
            "role": m.role,
            "content": m.content,
            "createdAt": m.created_at.isoformat(),
        } for m in msgs
    ]

    last_user_question = None
    last_assistant_index = None
    for idx, item in enumerate(items):
        if item["role"] == "user":
            last_user_question = item["content"]
        elif item["role"] == "assistant":
            last_assistant_index = idx

    if last_user_question and last_assistant_index is not None:
        suggestions = _suggest_lawyers(last_user_question, None)
        if suggestions:
            items[last_assistant_index]["lawyerSuggestions"] = suggestions

    payload = {
        "conversationId": conv.id,
        "title": conv.title,
        "page": page,
        "limit": limit,
        "items": items,
    }
    return etag_response(payload)

@bp.put("/conversations/<int:cid>")
@require_auth()
def rename_conversation(cid: int):
    conv = _get_conversation_or_404(cid, g.user.id)
    data = request.get_json() or {}
    title = (data.get("title") or "").strip()
    if not title:
        raise BadRequest("title required")
    if len(title) > 200:
        raise BadRequest("title too long (max 200 chars)")

    conv.title = title
    db.session.commit()
    return jsonify({"ok": True})

@bp.delete("/conversations/<int:cid>")
@require_auth()
def delete_conversation(cid: int):
    conv = _get_conversation_or_404(cid, g.user.id)

    db.session.delete(conv)
    db.session.commit()

    return jsonify({"ok": True})
