"""merge heads after llm settings

Revision ID: d82ea1d9b387
Revises: 8e9b4d1c2a3f, 1b7a2a9f2c8d
Create Date: 2026-02-05 13:21:49.463722

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'd82ea1d9b387'
down_revision = ('8e9b4d1c2a3f', '1b7a2a9f2c8d')
branch_labels = None
depends_on = None


def upgrade():
    pass


def downgrade():
    pass
