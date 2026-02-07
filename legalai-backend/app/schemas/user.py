from marshmallow import Schema, fields, validate

LANG_CHOICES = ["en", "ur"]
PROVINCE_CHOICES = ["Punjab", "Sindh", "KP", "Balochistan", "ICT"]

class UserSchema(Schema):
    id = fields.Int(dump_only=True)
    name = fields.Str(required=True, validate=validate.Length(min=1, max=120))
    email = fields.Email(required=True)
    phone = fields.Str(required=True, validate=validate.Length(min=5, max=30))
    cnic = fields.Str(required=True, validate=validate.Length(min=5, max=30))

    fatherName = fields.Str(allow_none=True)
    fatherCnic = fields.Str(allow_none=True)
    motherName = fields.Str(allow_none=True)
    motherCnic = fields.Str(allow_none=True)

    city = fields.Str(allow_none=True)
    gender = fields.Str(allow_none=True)
    age = fields.Int(allow_none=True)

    totalSiblings = fields.Int(load_default=0)
    brothers = fields.Int(load_default=0)
    sisters = fields.Int(load_default=0)

    avatarPath = fields.Str(dump_only=True)
    timezone = fields.Str(load_default="UTC")
    language = fields.Str(load_default="en", validate=validate.OneOf(LANG_CHOICES))
    province = fields.Str(dump_only=True, validate=validate.OneOf(PROVINCE_CHOICES))

    isAdmin = fields.Bool(dump_only=True)
    isEmailVerified = fields.Bool(dump_only=True)
    isDeleted = fields.Bool(dump_only=True)
    createdAt = fields.DateTime(dump_only=True, data_key="createdAt")
    updatedAt = fields.DateTime(dump_only=True, data_key="updatedAt")

class UpdateUserSchema(Schema):
    name = fields.Str(validate=validate.Length(min=1, max=120))
    phone = fields.Str(validate=validate.Length(min=5, max=30))
    cnic = fields.Str(validate=validate.Length(min=5, max=30))

    fatherName = fields.Str(allow_none=True)
    fatherCnic = fields.Str(allow_none=True)
    motherName = fields.Str(allow_none=True)
    motherCnic = fields.Str(allow_none=True)

    city = fields.Str(allow_none=True)
    gender = fields.Str(allow_none=True)
    age = fields.Int(allow_none=True)

    totalSiblings = fields.Int()
    brothers = fields.Int()
    sisters = fields.Int()

    timezone = fields.Str()
    language = fields.Str(validate=validate.OneOf(LANG_CHOICES))
