from marshmallow import Schema, fields, validate

class OkIdSchema(Schema):
    id = fields.Int(required=True)

class PaginationMetaSchema(Schema):
    page = fields.Int(required=True, validate=validate.Range(min=1))
    perPage = fields.Int(required=True, data_key="perPage", validate=validate.Range(min=1, max=100))
    total = fields.Int(required=True, validate=validate.Range(min=0))
    totalPages = fields.Int(required=True, data_key="totalPages", validate=validate.Range(min=0))
    hasNext = fields.Bool(required=True, data_key="hasNext")
    hasPrev = fields.Bool(required=True, data_key="hasPrev")