"""merge heads (google_sub + notifications)

Revision ID: 8e9b4d1c2a3f
Revises: 53fd8f361dbf, 7f6a3b2e1c4d
Create Date: 2026-02-03 13:20:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '8e9b4d1c2a3f'
down_revision = ('53fd8f361dbf', '7f6a3b2e1c4d')
branch_labels = None
depends_on = None


def upgrade():
    pass


def downgrade():
    pass
