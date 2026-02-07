from datetime import datetime
from app.extensions import db


class Feedback(db.Model):
    __tablename__ = "feedback"

    id = db.Column(db.BigInteger, primary_key=True)

    user_id = db.Column(
        db.BigInteger,
        db.ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )

    rating = db.Column(db.Integer, nullable=False) 
    comment = db.Column(db.Text, nullable=False)
    is_read = db.Column(db.Boolean, nullable=False, default=False, server_default="false", index=True)

    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
