"""set drafts template fk to set null

Revision ID: c2f4a1b9e7d0
Revises: d82ea1d9b387
Create Date: 2026-02-06 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "c2f4a1b9e7d0"
down_revision = "d82ea1d9b387"
branch_labels = None
depends_on = None


def upgrade():
    op.drop_constraint("drafts_template_id_fkey", "drafts", type_="foreignkey")
    op.create_foreign_key(
        "drafts_template_id_fkey",
        "drafts",
        "templates",
        ["template_id"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade():
    op.drop_constraint("drafts_template_id_fkey", "drafts", type_="foreignkey")
    op.create_foreign_key(
        "drafts_template_id_fkey",
        "drafts",
        "templates",
        ["template_id"],
        ["id"],
    )
