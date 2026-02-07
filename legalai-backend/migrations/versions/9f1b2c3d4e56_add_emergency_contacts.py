from alembic import op
import sqlalchemy as sa


revision = '9f1b2c3d4e56'
down_revision = '7d060b667514'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'emergency_contacts',
        sa.Column('id', sa.BigInteger(), primary_key=True),
        sa.Column('user_id', sa.BigInteger(), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('name', sa.String(length=120), nullable=False),
        sa.Column('relation', sa.String(length=80), nullable=False),
        sa.Column('country_code', sa.String(length=8), nullable=False, server_default='+92'),
        sa.Column('phone', sa.String(length=16), nullable=False),
        sa.Column('is_primary', sa.Boolean(), nullable=False, server_default=sa.text('false')),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.UniqueConstraint('user_id', 'phone', name='uq_emergency_contacts_user_phone'),
    )
    op.create_index('ix_emergency_contacts_user_id', 'emergency_contacts', ['user_id'])


def downgrade():
    op.drop_index('ix_emergency_contacts_user_id', table_name='emergency_contacts')
    op.drop_table('emergency_contacts')
