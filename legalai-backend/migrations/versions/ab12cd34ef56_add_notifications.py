"""add notifications and reminder notified_at

Revision ID: ab12cd34ef56
Revises: 8b390e6d1636
Create Date: 2026-02-02 12:30:00.000000

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision = "ab12cd34ef56"
down_revision = "8b390e6d1636"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("reminders", sa.Column("notified_at", sa.DateTime(), nullable=True))

    op.create_table(
        "notifications",
        sa.Column("id", sa.BigInteger(), primary_key=True),
        sa.Column("type", sa.String(length=50), nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column("data", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column(
            "scope", sa.String(length=20), nullable=False, server_default="broadcast"
        ),
        sa.Column("topic", sa.String(length=120), nullable=True),
        sa.Column(
            "user_id",
            sa.BigInteger(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=True,
        ),
        sa.Column("language", sa.String(length=10), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP"),
        ),
        sa.Column("expires_at", sa.DateTime(), nullable=True),
    )
    op.create_index("ix_notifications_user_id", "notifications", ["user_id"])
    op.create_index("ix_notifications_type", "notifications", ["type"])

    op.create_table(
        "notification_reads",
        sa.Column("id", sa.BigInteger(), primary_key=True),
        sa.Column(
            "notification_id",
            sa.BigInteger(),
            sa.ForeignKey("notifications.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "user_id",
            sa.BigInteger(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "read_at",
            sa.DateTime(),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP"),
        ),
    )
    op.create_index("ix_notification_reads_user_id", "notification_reads", ["user_id"])
    op.create_index(
        "ix_notification_reads_notification_id",
        "notification_reads",
        ["notification_id"],
    )

    op.create_table(
        "notification_preferences",
        sa.Column(
            "user_id",
            sa.BigInteger(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            primary_key=True,
        ),
        sa.Column(
            "content_updates",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
        sa.Column(
            "lawyer_updates",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
        sa.Column(
            "reminder_notifications",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP"),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP"),
        ),
    )


def downgrade():
    op.drop_table("notification_preferences")
    op.drop_index(
        "ix_notification_reads_notification_id", table_name="notification_reads"
    )
    op.drop_index("ix_notification_reads_user_id", table_name="notification_reads")
    op.drop_table("notification_reads")
    op.drop_index("ix_notifications_type", table_name="notifications")
    op.drop_index("ix_notifications_user_id", table_name="notifications")
    op.drop_table("notifications")
    op.drop_column("reminders", "notified_at")
