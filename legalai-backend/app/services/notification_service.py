from __future__ import annotations

from flask import current_app
from ..extensions import db
from ..models.notifications import Notification, NotificationPreference
from ..tasks.notifications_tasks import (
    send_broadcast_notification,
    send_user_notification,
)


CONTENT_UPDATE_TYPES = {
    "RIGHT_CREATED",
    "RIGHT_UPDATED",
    "TEMPLATE_CREATED",
    "TEMPLATE_UPDATED",
}
LAWYER_UPDATE_TYPES = {
    "LAWYER_CREATED",
    "LAWYER_UPDATED",
    "LAWYER_DEACTIVATED",
}
REMINDER_TYPES = {"REMINDER_DUE"}
ADMIN_NOTIFICATION_TYPES = {"ADMIN_CONTACT_MESSAGE", "ADMIN_FEEDBACK"}


class NotificationService:
    @staticmethod
    def get_preferences(user_id: int) -> NotificationPreference:
        pref = NotificationPreference.query.filter_by(user_id=user_id).first()
        if pref:
            return pref

        pref = NotificationPreference(user_id=user_id)
        db.session.add(pref)
        db.session.commit()
        return pref

    @staticmethod
    def update_preferences(user_id: int, data: dict) -> NotificationPreference:
        pref = NotificationService.get_preferences(user_id)
        if "contentUpdates" in data:
            pref.content_updates = bool(data.get("contentUpdates"))
        if "lawyerUpdates" in data:
            pref.lawyer_updates = bool(data.get("lawyerUpdates"))
        if "reminderNotifications" in data:
            pref.reminder_notifications = bool(data.get("reminderNotifications"))
        db.session.commit()
        return pref

    @staticmethod
    def allowed_types(pref: NotificationPreference) -> set[str]:
        allowed: set[str] = set()
        if pref.content_updates:
            allowed |= CONTENT_UPDATE_TYPES
        if pref.lawyer_updates:
            allowed |= LAWYER_UPDATE_TYPES
        if pref.reminder_notifications:
            allowed |= REMINDER_TYPES
        return allowed

    @staticmethod
    def should_send_to_user(
        notification_type: str, pref: NotificationPreference
    ) -> bool:
        if notification_type in CONTENT_UPDATE_TYPES:
            return pref.content_updates
        if notification_type in LAWYER_UPDATE_TYPES:
            return pref.lawyer_updates
        if notification_type in REMINDER_TYPES:
            return pref.reminder_notifications
        return True

    @staticmethod
    def create_broadcast(
        *,
        notification_type: str,
        title: str,
        body: str,
        data: dict | None = None,
        topic: str | None = None,
        language: str | None = None,
    ) -> Notification:
        n = Notification(
            type=notification_type,
            title=title,
            body=body,
            data=data or {},
            scope="broadcast",
            topic=topic,
            language=language,
        )
        db.session.add(n)
        db.session.commit()
        if not current_app.config.get("TESTING"):
            try:
                send_broadcast_notification.delay(n.id)
            except Exception:
                current_app.logger.warning("Failed to enqueue broadcast notification")
        return n

    @staticmethod
    def create_user_notification(
        *,
        user_id: int,
        notification_type: str,
        title: str,
        body: str,
        data: dict | None = None,
        language: str | None = None,
    ) -> Notification:
        n = Notification(
            type=notification_type,
            title=title,
            body=body,
            data=data or {},
            scope="user",
            user_id=user_id,
            language=language,
        )
        db.session.add(n)
        db.session.commit()
        if not current_app.config.get("TESTING"):
            try:
                send_user_notification.delay(n.id)
            except Exception:
                current_app.logger.warning("Failed to enqueue user notification")
        return n

    @staticmethod
    def build_title_body(
        notification_type: str, label: str | None = None
    ) -> tuple[str, str]:
        if notification_type == "RIGHT_CREATED":
            return ("New right added", label or "A new right is available.")
        if notification_type == "RIGHT_UPDATED":
            return ("Right updated", label or "A right has been updated.")
        if notification_type == "TEMPLATE_CREATED":
            return ("New template added", label or "A new template is available.")
        if notification_type == "TEMPLATE_UPDATED":
            return ("Template updated", label or "A template has been updated.")
        if notification_type == "LAWYER_CREATED":
            return ("New lawyer added", label or "A new lawyer is available.")
        if notification_type == "LAWYER_UPDATED":
            return ("Lawyer updated", label or "A lawyer profile has been updated.")
        if notification_type == "LAWYER_DEACTIVATED":
            return ("Lawyer removed", label or "A lawyer is no longer available.")
        if notification_type == "REMINDER_DUE":
            return ("Reminder", label or "You have a reminder.")
        return ("Update", label or "You have a new update.")

    @staticmethod
    def topics_for_type(notification_type: str) -> str | None:
        if notification_type in CONTENT_UPDATE_TYPES:
            return "content_updates"
        if notification_type in LAWYER_UPDATE_TYPES:
            return "lawyer_updates"
        return None

    @staticmethod
    def build_admin_title_body(
        kind: str, full_name: str | None, subject: str | None
    ) -> tuple[str, str]:
        name = (full_name or "User").strip() or "User"
        subject_label = (subject or "New update").strip() or "New update"
        if kind == "contact":
            return ("New contact message", f"{name} — {subject_label}")
        if kind == "feedback":
            return ("New feedback", f"{name} — {subject_label}")
        return ("New admin notification", f"{name} — {subject_label}")

    @staticmethod
    def create_admin_notification(
        *,
        user_id: int,
        notification_type: str,
        title: str,
        body: str,
        data: dict | None = None,
        language: str | None = None,
    ) -> Notification:
        n = Notification(
            type=notification_type,
            title=title,
            body=body,
            data=data or {},
            scope="user",
            user_id=user_id,
            language=language,
        )
        db.session.add(n)
        db.session.commit()
        return n
