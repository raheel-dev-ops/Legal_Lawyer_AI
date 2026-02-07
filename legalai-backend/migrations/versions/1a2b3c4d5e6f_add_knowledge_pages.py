"""add_knowledge_pages

Revision ID: 1a2b3c4d5e6f
Revises: 8b390e6d1636
Create Date: 2026-01-27 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '1a2b3c4d5e6f'
down_revision = '8b390e6d1636'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'knowledge_pages',
        sa.Column('id', sa.BigInteger(), primary_key=True),
        sa.Column('source_id', sa.BigInteger(), sa.ForeignKey('knowledge_sources.id', ondelete='CASCADE')),
        sa.Column('page_number', sa.Integer(), nullable=False),
        sa.Column('image_path', sa.String(length=512), nullable=False),
        sa.Column('width', sa.Integer(), nullable=True),
        sa.Column('height', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
    )


def downgrade():
    op.drop_table('knowledge_pages')
