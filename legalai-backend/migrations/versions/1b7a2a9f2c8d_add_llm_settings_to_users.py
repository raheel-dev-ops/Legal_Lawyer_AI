"""add llm settings to users

Revision ID: 1b7a2a9f2c8d
Revises: f1f94bec5387
Create Date: 2026-02-05 12:40:00.000000
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "1b7a2a9f2c8d"
down_revision = "f1f94bec5387"
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table("users") as batch_op:
        batch_op.add_column(sa.Column("chat_provider", sa.String(length=32), nullable=False, server_default="openai"))
        batch_op.add_column(sa.Column("chat_model", sa.String(length=128), nullable=True))
        batch_op.add_column(sa.Column("voice_provider", sa.String(length=32), nullable=False, server_default="openai"))
        batch_op.add_column(sa.Column("voice_model", sa.String(length=128), nullable=True))

        batch_op.add_column(sa.Column("openai_api_key_enc", sa.Text(), nullable=True))
        batch_op.add_column(sa.Column("openrouter_api_key_enc", sa.Text(), nullable=True))
        batch_op.add_column(sa.Column("groq_api_key_enc", sa.Text(), nullable=True))
        batch_op.add_column(sa.Column("deepseek_api_key_enc", sa.Text(), nullable=True))
        batch_op.add_column(sa.Column("grok_api_key_enc", sa.Text(), nullable=True))
        batch_op.add_column(sa.Column("anthropic_api_key_enc", sa.Text(), nullable=True))


def downgrade():
    with op.batch_alter_table("users") as batch_op:
        batch_op.drop_column("anthropic_api_key_enc")
        batch_op.drop_column("grok_api_key_enc")
        batch_op.drop_column("deepseek_api_key_enc")
        batch_op.drop_column("groq_api_key_enc")
        batch_op.drop_column("openrouter_api_key_enc")
        batch_op.drop_column("openai_api_key_enc")

        batch_op.drop_column("voice_model")
        batch_op.drop_column("voice_provider")
        batch_op.drop_column("chat_model")
        batch_op.drop_column("chat_provider")
