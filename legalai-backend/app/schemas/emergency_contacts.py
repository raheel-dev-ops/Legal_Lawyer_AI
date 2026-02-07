from marshmallow import Schema, fields, validate


class EmergencyContactCreateSchema(Schema):
    name = fields.Str(required=True, validate=validate.Length(min=1, max=120))
    relation = fields.Str(required=True, validate=validate.Length(min=1, max=80))
    phone = fields.Str(required=True, validate=validate.Length(min=5, max=20))
    countryCode = fields.Str(required=True, data_key="countryCode", validate=validate.Length(min=2, max=8))
    isPrimary = fields.Bool(required=False, data_key="isPrimary")


class EmergencyContactUpdateSchema(Schema):
    name = fields.Str(validate=validate.Length(min=1, max=120))
    relation = fields.Str(validate=validate.Length(min=1, max=80))
    phone = fields.Str(validate=validate.Length(min=5, max=20))
    countryCode = fields.Str(data_key="countryCode", validate=validate.Length(min=2, max=8))
    isPrimary = fields.Bool(data_key="isPrimary")


class EmergencyContactSchema(Schema):
    id = fields.Int(dump_only=True)
    name = fields.Str(required=True)
    relation = fields.Str(required=True)
    phone = fields.Str(required=True)
    countryCode = fields.Str(required=True, data_key="countryCode")
    isPrimary = fields.Bool(required=True, data_key="isPrimary")
    createdAt = fields.DateTime(dump_only=True, data_key="createdAt")
    updatedAt = fields.DateTime(dump_only=True, data_key="updatedAt")
