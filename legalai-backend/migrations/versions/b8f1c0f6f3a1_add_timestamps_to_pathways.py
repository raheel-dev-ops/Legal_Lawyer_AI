"""add timestamps to pathways

Revision ID: b8f1c0f6f3a1
Revises: c2f4a1b9e7d0
Create Date: 2026-02-06 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "b8f1c0f6f3a1"
down_revision = "c2f4a1b9e7d0"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "pathways",
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.add_column(
        "pathways",
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )


def downgrade():
    op.drop_column("pathways", "updated_at")
    op.drop_column("pathways", "created_at")
