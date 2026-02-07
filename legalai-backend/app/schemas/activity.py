from marshmallow import Schema, fields, validate

ITEM_TYPES = ["right", "template", "pathway"]

class BookmarkCreateSchema(Schema):
    itemType = fields.Str(required=True, validate=validate.OneOf(ITEM_TYPES))
    itemId = fields.Int(required=True, data_key="itemId")

class BookmarkSchema(BookmarkCreateSchema):
    id = fields.Int(dump_only=True)

class ActivityEventSchema(Schema):
    type = fields.Str(required=True)
    payload = fields.Dict(load_default=dict)
    createdAt = fields.DateTime(dump_only=True, data_key="createdAt")

class ActivityLogSchema(Schema):
    eventType = fields.Str(required=True, data_key="eventType")
    payload = fields.Dict(load_default=dict)