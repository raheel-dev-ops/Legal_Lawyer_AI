from marshmallow import Schema, fields, validate, validates, ValidationError


class ContactUsSchema(Schema):
    fullName = fields.Str(required=True, validate=validate.Length(min=1, max=200))
    email = fields.Email(required=True, validate=validate.Length(min=3, max=255))
    phone = fields.Str(required=True, validate=validate.Length(min=1, max=50))
    subject = fields.Str(required=True, validate=validate.Length(min=1, max=200))
    description = fields.Str(required=True, validate=validate.Length(min=1))

    @validates("fullName")
    def _name(self, v: str):
        if not v.strip():
            raise ValidationError("Full name is required")

    @validates("phone")
    def _phone(self, v: str):
        if not v.strip():
            raise ValidationError("Phone is required")

    @validates("subject")
    def _subject(self, v: str):
        if not v.strip():
            raise ValidationError("Subject is required")

    @validates("description")
    def _desc(self, v: str):
        if not v.strip():
            raise ValidationError("Description is required")


class FeedbackSchema(Schema):
    rating = fields.Int(required=True, validate=validate.Range(min=1, max=5))
    comment = fields.Str(required=True, validate=validate.Length(min=1))

    @validates("rating")
    def _rating(self, v: int):
        if v < 1 or v > 5:
            raise ValidationError("Rating must be between 1 and 5")

    @validates("comment")
    def _comment(self, v: str):
        if not v.strip():
            raise ValidationError("Comment is required")


class ContactMessageSchema(Schema):
    id = fields.Int(dump_only=True)
    userId = fields.Int(allow_none=True, data_key="userId")
    fullName = fields.Str(required=True)
    email = fields.Email(required=True)
    phone = fields.Str(required=True)
    subject = fields.Str(required=True)
    description = fields.Str(allow_none=True)
    createdAt = fields.DateTime(dump_only=True, data_key="createdAt")


class FeedbackListItemSchema(Schema):
    id = fields.Int(dump_only=True)
    userId = fields.Int(required=True, data_key="userId")
    userEmail = fields.Email(required=True, data_key="userEmail")
    rating = fields.Int(required=True, validate=validate.Range(min=1, max=5))
    commentPreview = fields.Str(required=True, data_key="commentPreview")
    isRead = fields.Bool(required=True, data_key="isRead")
    createdAt = fields.DateTime(dump_only=True, data_key="createdAt")


class FeedbackDetailSchema(Schema):
    id = fields.Int(dump_only=True)
    userId = fields.Int(required=True, data_key="userId")
    userEmail = fields.Email(allow_none=True, data_key="userEmail")
    rating = fields.Int(required=True, validate=validate.Range(min=1, max=5))
    comment = fields.Str(required=True)
    isRead = fields.Bool(required=True, data_key="isRead")
    createdAt = fields.DateTime(dump_only=True, data_key="createdAt")


class FeedbackSummarySchema(Schema):
    avgRating = fields.Float(required=True, data_key="avgRating")
    totalFeedback = fields.Int(required=True, data_key="totalFeedback")
    unreadCount = fields.Int(required=True, data_key="unreadCount")
