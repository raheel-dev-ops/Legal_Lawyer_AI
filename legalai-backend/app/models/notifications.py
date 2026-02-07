from datetime import datetime
from sqlalchemy import JSON
from sqlalchemy.dialects.postgresql import JSONB
from ..extensions import db


class Notification(db.Model):
    __tablename__ = "notifications"

    id = db.Column(db.BigInteger, primary_key=True)
    type = db.Column(db.String(50), nullable=False, index=True)
    title = db.Column(db.String(200), nullable=False)
    body = db.Column(db.Text, nullable=False)
    data = db.Column(JSON().with_variant(JSONB, "postgresql"), default=dict)
    scope = db.Column(db.String(20), nullable=False, default="broadcast")
    topic = db.Column(db.String(120))
    user_id = db.Column(
        db.BigInteger, db.ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    language = db.Column(db.String(10))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    expires_at = db.Column(db.DateTime)


class NotificationRead(db.Model):
    __tablename__ = "notification_reads"

    id = db.Column(db.BigInteger, primary_key=True)
    notification_id = db.Column(
        db.BigInteger,
        db.ForeignKey("notifications.id", ondelete="CASCADE"),
        index=True,
    )
    user_id = db.Column(
        db.BigInteger, db.ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    read_at = db.Column(db.DateTime, default=datetime.utcnow)


class NotificationPreference(db.Model):
    __tablename__ = "notification_preferences"

    user_id = db.Column(
        db.BigInteger,
        db.ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    content_updates = db.Column(
        db.Boolean, nullable=False, default=True, server_default="true"
    )
    lawyer_updates = db.Column(
        db.Boolean, nullable=False, default=True, server_default="true"
    )
    reminder_notifications = db.Column(
        db.Boolean, nullable=False, default=True, server_default="true"
    )
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(
        db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )
