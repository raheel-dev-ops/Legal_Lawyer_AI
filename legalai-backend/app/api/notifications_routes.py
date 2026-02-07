from flask import Blueprint, request, jsonify, g
from sqlalchemy import and_, or_
from werkzeug.exceptions import BadRequest
from ._auth_guard import require_auth
from ..extensions import db
from ..models.notifications import Notification, NotificationRead
from ..models.reminders import DeviceToken
from ..services.notification_service import NotificationService
from ..utils.http_cache import etag_response


bp = Blueprint("notifications", __name__)


@bp.get("")
@require_auth()
def list_notifications():
    limit = request.args.get("limit", 20)
    before = request.args.get("before")
    try:
        limit = min(max(int(limit), 1), 100)
    except (TypeError, ValueError):
        raise BadRequest("Invalid limit")

    pref = NotificationService.get_preferences(g.user.id)
    allowed = NotificationService.allowed_types(pref)
    if not allowed:
        return etag_response({"items": []})

    q = Notification.query.filter(Notification.type.in_(allowed)).filter(
        or_(Notification.scope == "broadcast", Notification.user_id == g.user.id)
    )
    if before:
        try:
            before_id = int(before)
            q = q.filter(Notification.id < before_id)
        except (TypeError, ValueError):
            raise BadRequest("Invalid before")

    items = q.order_by(Notification.id.desc()).limit(limit).all()
    ids = [n.id for n in items]

    read_rows = []
    if ids:
        read_rows = NotificationRead.query.filter(
            NotificationRead.user_id == g.user.id,
            NotificationRead.notification_id.in_(ids),
        ).all()
    read_map = {r.notification_id: r.read_at for r in read_rows}

    payload = []
    for n in items:
        payload.append(
            {
                "id": n.id,
                "type": n.type,
                "title": n.title,
                "body": n.body,
                "data": n.data or {},
                "scope": n.scope,
                "createdAt": n.created_at.isoformat() if n.created_at else None,
                "isRead": n.id in read_map,
                "readAt": read_map.get(n.id).isoformat()
                if read_map.get(n.id)
                else None,
            }
        )

    return etag_response({"items": payload})


@bp.post("/<int:notification_id>/read")
@require_auth()
def mark_read(notification_id: int):
    n = Notification.query.get_or_404(notification_id)
    if n.scope == "user" and n.user_id != g.user.id:
        raise BadRequest("Not allowed")

    existing = NotificationRead.query.filter_by(
        notification_id=n.id, user_id=g.user.id
    ).first()
    if not existing:
        db.session.add(NotificationRead(notification_id=n.id, user_id=g.user.id))
        db.session.commit()
    return jsonify({"ok": True})


@bp.post("/mark-all-read")
@require_auth()
def mark_all_read():
    pref = NotificationService.get_preferences(g.user.id)
    allowed = NotificationService.allowed_types(pref)
    if not allowed:
        return jsonify({"ok": True, "updated": 0})

    q = db.session.query(Notification.id).filter(
        Notification.type.in_(allowed),
        or_(Notification.scope == "broadcast", Notification.user_id == g.user.id),
    )
    q = q.outerjoin(
        NotificationRead,
        and_(
            NotificationRead.notification_id == Notification.id,
            NotificationRead.user_id == g.user.id,
        ),
    ).filter(NotificationRead.id.is_(None))

    ids = [row[0] for row in q.all()]
    if not ids:
        return jsonify({"ok": True, "updated": 0})

    rows = [{"notification_id": nid, "user_id": g.user.id} for nid in ids]
    db.session.bulk_insert_mappings(NotificationRead, rows)
    db.session.commit()
    return jsonify({"ok": True, "updated": len(ids)})


@bp.get("/unread-count")
@require_auth()
def unread_count():
    pref = NotificationService.get_preferences(g.user.id)
    allowed = NotificationService.allowed_types(pref)
    if not allowed:
        return etag_response({"count": 0})

    q = db.session.query(Notification.id).filter(
        Notification.type.in_(allowed),
        or_(Notification.scope == "broadcast", Notification.user_id == g.user.id),
    )
    q = q.outerjoin(
        NotificationRead,
        and_(
            NotificationRead.notification_id == Notification.id,
            NotificationRead.user_id == g.user.id,
        ),
    ).filter(NotificationRead.id.is_(None))

    return etag_response({"count": q.count()})


@bp.get("/preferences")
@require_auth()
def get_preferences():
    pref = NotificationService.get_preferences(g.user.id)
    return jsonify(
        {
            "contentUpdates": bool(pref.content_updates),
            "lawyerUpdates": bool(pref.lawyer_updates),
            "reminderNotifications": bool(pref.reminder_notifications),
        }
    )


@bp.put("/preferences")
@require_auth()
def update_preferences():
    data = request.get_json() or {}
    pref = NotificationService.update_preferences(g.user.id, data)
    return jsonify(
        {
            "contentUpdates": bool(pref.content_updates),
            "lawyerUpdates": bool(pref.lawyer_updates),
            "reminderNotifications": bool(pref.reminder_notifications),
        }
    )


@bp.post("/register-device-token")
@require_auth()
def register_device():
    data = request.get_json() or {}
    if data.get("platform") not in {"android", "ios"} or not data.get("token"):
        raise BadRequest("platform and token required")

    DeviceToken.query.filter_by(token=data["token"]).delete()
    dt = DeviceToken(user_id=g.user.id, platform=data["platform"], token=data["token"])
    db.session.add(dt)
    db.session.commit()
    return jsonify({"ok": True})


@bp.post("/unregister-device-token")
@require_auth()
def unregister_device():
    data = request.get_json() or {}
    token = data.get("token")
    if not token:
        raise BadRequest("token required")

    DeviceToken.query.filter_by(user_id=g.user.id, token=token).delete()
    db.session.commit()
    return jsonify({"ok": True})
