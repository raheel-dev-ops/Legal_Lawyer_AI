from datetime import datetime
from ..extensions import db


class EmergencyContact(db.Model):
    __tablename__ = "emergency_contacts"
    id = db.Column(db.BigInteger, primary_key=True)
    user_id = db.Column(db.BigInteger, db.ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    name = db.Column(db.String(120), nullable=False)
    relation = db.Column(db.String(80), nullable=False)
    country_code = db.Column(db.String(8), nullable=False, default="+92")
    phone = db.Column(db.String(16), nullable=False)
    is_primary = db.Column(db.Boolean, default=False, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    __table_args__ = (
        db.UniqueConstraint("user_id", "phone", name="uq_emergency_contacts_user_phone"),
    )
