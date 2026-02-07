import time
from flask import current_app

from .celery_app import celery
from ..models.chat import ChatMessage
from ..services.rag_service import RAGService
from ..services.llm_service import LLMService
from ..services.rag_evaluation_service import RAGEvaluationService


def _recent_conversation_messages(conversation_id: int, user_id: int, limit: int = 10) -> list[dict]:
    rows = (
        ChatMessage.query
        .filter_by(conversation_id=conversation_id, user_id=user_id)
        .order_by(ChatMessage.created_at.desc())
        .limit(limit)
        .all()
    )
    rows = list(reversed(rows))
    return [{"role": r.role, "content": r.content} for r in rows]


def _friendly_error(language: str, message: str | None = None) -> str:
    if language == "ur":
        return (
            "معذرت، ابھی جواب تیار نہیں ہو سکا۔ براہِ کرم کچھ دیر بعد دوبارہ کوشش کریں۔"
            if not message
            else message
        )
    return message or "Sorry, the answer could not be generated right now. Please try again shortly."


@celery.task(bind=True, max_retries=1)
def process_chat_async(
    self,
    *,
    user_id: int,
    conversation_id: int,
    question: str,
    language: str = "en",
    province: str | None = None,
    memory_limit: int = 10,
    provider: str | None = None,
    model: str | None = None,
    api_keys: dict | None = None,
):
    """
    Background chat generation to avoid request timeouts.
    Writes assistant message to DB when done (or error message on failure).
    """
    t0 = time.perf_counter()
    try:
        history = _recent_conversation_messages(conversation_id, user_id, limit=memory_limit)

        retrieval = RAGService.hybrid_search(question, language=language)
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
                question=question,
                contexts=contexts,
                images=image_contexts,
                language=language,
                province=province,
                history=history,
                provider_override=provider,
                model_override=model,
                api_keys=api_keys,
            )
        else:
            answer, prompt_messages, _ = LLMService.chat_legal_awareness(
                question=question,
                contexts=contexts,
                language=language,
                province=province,
                history=history,
                provider_override=provider,
                model_override=model,
                api_keys=api_keys,
            )
        llm_time_ms = int((time.perf_counter() - llm_start) * 1000)

        ChatMessage.add_and_trim(
            user_id=user_id,
            conversation_id=conversation_id,
            role="assistant",
            content=answer,
            max_messages=100,
            commit=True,
        )

        total_time_ms = int((time.perf_counter() - t0) * 1000)
        RAGEvaluationService.log_evaluation(
            user_id=user_id,
            conversation_id=conversation_id,
            language=language,
            safe_mode=False,
            is_new_conversation=False,
            question=question,
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
            chat_model=model or current_app.config.get("CHAT_MODEL"),
            prompt_messages=prompt_messages,
            completion_text=answer,
        )
    except Exception as e:
        current_app.logger.exception("Async chat task failed: %s", str(e))
        error_text = _friendly_error(language)
        try:
            ChatMessage.add_and_trim(
                user_id=user_id,
                conversation_id=conversation_id,
                role="assistant",
                content=error_text,
                max_messages=100,
                commit=True,
            )
        except Exception:
            current_app.logger.exception("Failed to store async error message.")
        raise
