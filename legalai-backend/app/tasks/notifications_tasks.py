from .celery_app import celery
from ..extensions import db
from ..models.notifications import Notification
from ..models.reminders import DeviceToken
from ..services.push_service import PushService


@celery.task(bind=True)
def send_broadcast_notification(self, notification_id: int):
    n = Notification.query.get(notification_id)
    if not n:
        return

    if n.scope != "broadcast":
        return

    try:
        if n.topic:
            PushService.send_fcm_topic(n.topic, n.title, n.body, data=_build_payload(n))
        else:
            tokens = [t.token for t in DeviceToken.query.all()]
            PushService.send_fcm(tokens, n.title, n.body, data=_build_payload(n))
    except Exception:
        db.session.rollback()
        raise


@celery.task(bind=True)
def send_user_notification(self, notification_id: int):
    n = Notification.query.get(notification_id)
    if not n:
        return

    if n.scope != "user" or not n.user_id:
        return

    try:
        PushService.send_to_user(n.user_id, n.title, n.body, data=_build_payload(n))
    except Exception:
        db.session.rollback()
        raise


def _build_payload(n: Notification) -> dict:
    payload = {
        "notificationId": n.id,
        "type": n.type,
    }
    if isinstance(n.data, dict):
        payload.update(n.data)
    return payload
