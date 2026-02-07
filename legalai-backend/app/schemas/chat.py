from marshmallow import Schema, fields, validate

ROLE_CHOICES = ["user", "assistant", "system"]

class ChatAskSchema(Schema):
    question = fields.Str(required=True, validate=validate.Length(min=1, max=2000))
    conversationId = fields.Int(allow_none=True, data_key="conversationId")

class ChatAskResponseSchema(Schema):
    answer = fields.Str(required=True)
    conversationId = fields.Int(allow_none=True, data_key="conversationId")
    contextsUsed = fields.Int(required=True, data_key="contextsUsed")

class ConversationSchema(Schema):
    id = fields.Int(dump_only=True)
    title = fields.Str(required=True, validate=validate.Length(min=1, max=200))
    createdAt = fields.DateTime(dump_only=True, data_key="createdAt")
    updatedAt = fields.DateTime(dump_only=True, data_key="updatedAt")
    lastMessageSnippet = fields.Str(required=True, validate=validate.Length(max=120), data_key="lastMessageSnippet")

class PaginatedConversationsSchema(Schema):
    page = fields.Int(required=True)
    limit = fields.Int(required=True)
    items = fields.List(fields.Nested(ConversationSchema()), required=True)

class ChatMessageSchema(Schema):
    id = fields.Int(dump_only=True)
    role = fields.Str(required=True, validate=validate.OneOf(ROLE_CHOICES))
    content = fields.Str(required=True)
    createdAt = fields.DateTime(dump_only=True, data_key="createdAt")

class ConversationMessagesResponseSchema(Schema):
    conversationId = fields.Int(required=True, data_key="conversationId")
    title = fields.Str(required=True)
    page = fields.Int(required=True)
    limit = fields.Int(required=True)
    items = fields.List(fields.Nested(ChatMessageSchema()), required=True)

class ConversationRenameSchema(Schema):
    title = fields.Str(required=True, validate=validate.Length(min=1, max=200))

class ChatPaginationQuerySchema(Schema):
    page = fields.Int(load_default=1)
    limit = fields.Int(load_default=20)