from marshmallow import Schema, fields

class ContentFileSchema(Schema):
    url = fields.Str(required=True)

class ContentFilesSchema(Schema):
    rights = fields.Nested(ContentFileSchema(), required=True)
    templates = fields.Nested(ContentFileSchema(), required=True)

class ContentManifestSchema(Schema):
    version = fields.Int(required=True)
    files = fields.Nested(ContentFilesSchema(), required=True)

class ContentRightSchema(Schema):
    id = fields.Int(dump_only=True)
    topic = fields.Str(required=True)
    body = fields.Str(required=True)
    category = fields.Str(allow_none=True)
    language = fields.Str(required=True)
    tags = fields.List(fields.Str(), load_default=[])

class ContentTemplateSchema(Schema):
    id = fields.Int(dump_only=True)
    title = fields.Str(required=True)
    category = fields.Str(allow_none=True)
    description = fields.Str(allow_none=True)
    body = fields.Str(required=True)