"""
Task imports for Celery autodiscovery.
"""

from .email_tasks import (
    send_verification_email_task,
    send_password_reset_email_task,
    send_password_changed_email_task,
)
from .ingestion_tasks import ingest_source, retry_stale_knowledge_sources
from .reminders_tasks import send_due_reminders
from .notifications_tasks import send_broadcast_notification, send_user_notification
from .evaluation_tasks import log_rag_evaluation_async
from .chat_tasks import process_chat_async

__all__ = [
    "send_verification_email_task",
    "send_password_reset_email_task",
    "send_password_changed_email_task",
    "ingest_source",
    "retry_stale_knowledge_sources",
    "send_due_reminders",
    "send_broadcast_notification",
    "send_user_notification",
    "log_rag_evaluation_async",
    "process_chat_async",
]
