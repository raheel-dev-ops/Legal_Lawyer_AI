from datetime import timezone
from flask import Blueprint, request, jsonify, g, current_app
from werkzeug.exceptions import BadRequest
from ._auth_guard import require_auth, safe_mode_on
from ..models.user import User
from ..models.activity import Bookmark, ActivityEvent
from ..services.storage_service import StorageService
from ..services import llm_settings_service as llm_settings
from ..exceptions import AppError
from ..extensions import db, limiter

bp = Blueprint("users", __name__)
MAX_ACTIVITY_EVENTS = 6

@bp.get("/me")
@require_auth()
def me():
    u: User = g.user
    return jsonify({
        "id": u.id, "name": u.name, "email": u.email, "phone": u.phone, "cnic": u.cnic,
        "fatherName": u.father_name, "fatherCnic": u.father_cnic,
        "motherName": u.mother_name, "motherCnic": u.mother_cnic,
        "city": u.city, "gender": u.gender, "age": u.age,
        "totalSiblings": u.total_siblings, "brothers": u.brothers, "sisters": u.sisters,
        "avatarPath": u.avatar_path, "timezone": u.timezone, "language": u.language,
        "isAdmin": u.is_admin, "isEmailVerified": u.is_email_verified
    })

@bp.put("/me")
@require_auth()
@limiter.limit("30 per minute")
def update_me():
    if safe_mode_on():
        return jsonify({"ok": False, "message": "Safe mode enabled", "reason": "Safe mode"}), 403

    data = request.get_json() or {}
    u: User = g.user

    for k, attr in [
        ("name","name"),("phone","phone"),("cnic","cnic"),
        ("fatherName","father_name"),("fatherCnic","father_cnic"),
        ("motherName","mother_name"),("motherCnic","mother_cnic"),
        ("city","city"),("gender","gender"),("age","age"),
        ("totalSiblings","total_siblings"),("brothers","brothers"),("sisters","sisters"),
        ("timezone","timezone"), ("language","language")
    ]:
        if k in data:
            setattr(u, attr, data[k])
    if "language" in data:
        lang = str(data.get("language") or "").strip().lower()
        if lang not in {"en", "ur"}:
            raise BadRequest("Invalid language")
        u.language = lang
    db.session.commit()
    return jsonify({"ok": True})

@bp.post("/me/avatar")
@limiter.limit("10 per minute")
@require_auth()
def upload_avatar():
    if safe_mode_on():
        return jsonify({"ok": False, "message": "Safe mode enabled", "reason": "Safe mode"}), 403

    if "file" not in request.files:
        raise BadRequest("Missing file")
    path = StorageService.save_file(request.files["file"], "avatars")
    g.user.avatar_path = StorageService.public_path(path)
    db.session.commit()
    db.session.add(
        ActivityEvent(
            user_id=g.user.id,
            event_type="PROFILE_IMAGE_UPDATED",
            payload={},
        )
    )
    db.session.commit()
    return jsonify({"avatarPath": g.user.avatar_path})

@bp.post("/me/bookmarks")
@require_auth()
def add_bookmark():
    if safe_mode_on():
        return jsonify({"ok": False, "message": "Safe mode enabled", "reason": "Safe mode"}), 403

    d = request.get_json() or {}
    if d.get("itemType") not in {"right","template","pathway"}:
        raise BadRequest("Invalid itemType")

    bm = Bookmark(user_id=g.user.id, item_type=d["itemType"], item_id=int(d["itemId"]))
    db.session.add(bm); db.session.commit()
    return jsonify({"id": bm.id}), 201

@bp.get("/me/bookmarks")
@require_auth()
def list_bookmarks():
    q = Bookmark.query.filter_by(user_id=g.user.id).order_by(Bookmark.created_at.desc()).all()
    return jsonify([{"id": b.id, "itemType": b.item_type, "itemId": b.item_id} for b in q])

@bp.delete("/me/bookmarks/<int:bid>")
@require_auth()
def delete_bookmark(bid):
    if safe_mode_on():
        return jsonify({"ok": False, "message": "Safe mode enabled", "reason": "Safe mode"}), 403
    Bookmark.query.filter_by(id=bid, user_id=g.user.id).delete()
    db.session.commit()
    return jsonify({"ok": True})

@bp.post("/me/activity")
@require_auth()
def log_activity():
    if safe_mode_on():
        return jsonify({"ok": True}) 
    d = request.get_json() or {}
    ev = ActivityEvent(user_id=g.user.id, event_type=d.get("eventType","unknown"), payload=d.get("payload",{}))
    db.session.add(ev); db.session.commit()
    _prune_activity_events(g.user.id, MAX_ACTIVITY_EVENTS)
    return jsonify({"ok": True})

@bp.get("/me/activity")
@require_auth()
def get_activity():
    q = (ActivityEvent.query.filter_by(user_id=g.user.id)
         .order_by(ActivityEvent.created_at.desc()).limit(MAX_ACTIVITY_EVENTS).all())
    return jsonify([{"type": e.event_type, "payload": e.payload, "createdAt": _iso_utc(e.created_at)} for e in q])

@bp.delete("/me/activity")
@require_auth()
def clear_activity():
    ActivityEvent.query.filter_by(user_id=g.user.id).delete()
    db.session.commit()
    return jsonify({"ok": True})

@bp.get("/me/llm-settings")
@require_auth()
def get_llm_settings():
    u: User = g.user
    chat_provider = llm_settings.chat_provider_for(u)
    voice_provider = llm_settings.voice_provider_for(u)
    chat_model = llm_settings.chat_model_for(u) or current_app.config.get("CHAT_MODEL", "")
    voice_model = llm_settings.voice_model_for(u) or ""
    return jsonify({
        "chatProvider": chat_provider,
        "chatModel": chat_model,
        "voiceProvider": voice_provider,
        "voiceModel": voice_model,
        "keys": llm_settings.key_status(u),
    })

@bp.put("/me/llm-settings")
@require_auth()
@limiter.limit("30 per minute")
def update_llm_settings():
    if safe_mode_on():
        return jsonify({"ok": False, "message": "Safe mode enabled", "reason": "Safe mode"}), 403

    data = request.get_json() or {}
    u: User = g.user

    if "chatProvider" in data:
        u.chat_provider = llm_settings.chat_provider_for(u, data.get("chatProvider"))
    if "chatModel" in data:
        u.chat_model = (data.get("chatModel") or "").strip() or None
    if "voiceProvider" in data:
        u.voice_provider = llm_settings.voice_provider_for(u, data.get("voiceProvider"))
    if "voiceModel" in data:
        u.voice_model = (data.get("voiceModel") or "").strip() or None

    keys = data.get("keys")
    if keys is not None:
        if not isinstance(keys, dict):
            raise BadRequest("keys must be an object")
        for provider in llm_settings.CHAT_PROVIDERS:
            if provider not in keys:
                continue
            raw = keys.get(provider)
            if raw is None:
                continue
            if not isinstance(raw, str):
                raise BadRequest(f"{provider} key must be a string")
            value = raw.strip()
            try:
                if value:
                    if len(value) > 1000:
                        raise BadRequest(f"{provider} key is too long")
                    llm_settings.set_key(u, provider, value)
                else:
                    llm_settings.set_key(u, provider, None)
            except RuntimeError as e:
                raise AppError(str(e), code=500, error="server_error")

    db.session.commit()
    return jsonify({"ok": True})

def _prune_activity_events(user_id: int, keep: int):
    extra = (ActivityEvent.query.filter_by(user_id=user_id)
             .order_by(ActivityEvent.created_at.desc())
             .offset(keep).all())
    if not extra:
        return
    for ev in extra:
        db.session.delete(ev)
    db.session.commit()

def _iso_utc(value):
    if value is None:
        return None
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    else:
        value = value.astimezone(timezone.utc)
    return value.isoformat().replace("+00:00", "Z")
