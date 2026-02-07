from marshmallow import Schema, fields, validate

class LawyerPublicSchema(Schema):
    id = fields.Int(dump_only=True)
    name = fields.Str(required=True, data_key="name")
    email = fields.Email(required=True)
    phone = fields.Str(required=True)
    category = fields.Str(required=True)
    profilePicturePath = fields.Str(required=True, data_key="profilePicturePath")

class LawyerAdminSchema(Schema):
    id = fields.Int(dump_only=True)
    fullName = fields.Str(required=True, data_key="fullName")
    email = fields.Email(required=True)
    phone = fields.Str(required=True)
    category = fields.Str(required=True)
    profilePicturePath = fields.Str(required=True, data_key="profilePicturePath")
    isActive = fields.Bool(required=True, data_key="isActive")
    createdAt = fields.DateTime(dump_only=True, data_key="createdAt")
    updatedAt = fields.DateTime(dump_only=True, data_key="updatedAt")

class LawyerCreateSchema(Schema):
    fullName = fields.Str(required=True, validate=validate.Length(min=1, max=200), data_key="fullName")
    email = fields.Email(required=True, validate=validate.Length(min=3, max=255))
    phone = fields.Str(required=True, validate=validate.Length(min=1, max=50))
    category = fields.Str(required=True, validate=validate.Length(min=1, max=120))

class LawyerUpdateSchema(Schema):
    fullName = fields.Str(validate=validate.Length(min=1, max=200), data_key="fullName")
    email = fields.Email(validate=validate.Length(min=3, max=255))
    phone = fields.Str(validate=validate.Length(min=1, max=50))
    category = fields.Str(validate=validate.Length(min=1, max=120))
    isActive = fields.Bool(data_key="isActive")