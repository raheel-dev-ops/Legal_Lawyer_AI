"""add is_read to feedback

Revision ID: 2f6d6a2f4e5a
Revises: 0c2c48c4c6a1
Create Date: 2026-01-20 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


revision = '2f6d6a2f4e5a'
down_revision = '0c2c48c4c6a1'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        'feedback',
        sa.Column('is_read', sa.Boolean(), nullable=False, server_default=sa.text('false')),
    )
    op.create_index('ix_feedback_is_read', 'feedback', ['is_read'])


def downgrade():
    op.drop_index('ix_feedback_is_read', table_name='feedback')
    op.drop_column('feedback', 'is_read')
