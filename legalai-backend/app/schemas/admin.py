from marshmallow import Schema, fields, validate

class AdminUserListItemSchema(Schema):
    id = fields.Int(dump_only=True)
    name = fields.Str(required=True)
    email = fields.Email(required=True)
    phone = fields.Str(required=True)
    cnic = fields.Str(required=True)
    isAdmin = fields.Bool(required=True, data_key="isAdmin")
    isEmailVerified = fields.Bool(required=True, data_key="isEmailVerified")
    isDeleted = fields.Bool(required=True, data_key="isDeleted")
    createdAt = fields.DateTime(dump_only=True, data_key="createdAt")

class AdminUserCreateSchema(Schema):
    name = fields.Str(required=True, validate=validate.Length(min=1, max=120))
    email = fields.Email(required=True, validate=validate.Length(min=3, max=255))
    phone = fields.Str(required=True, validate=validate.Length(min=1, max=50))
    cnic = fields.Str(required=True, validate=validate.Length(min=5, max=30))
    password = fields.Str(required=True, validate=validate.Length(min=8))
    isAdmin = fields.Bool(load_default=False, data_key="isAdmin")

class AdminUserUpdateSchema(Schema):
    name = fields.Str(validate=validate.Length(min=1, max=120))
    phone = fields.Str(validate=validate.Length(min=1, max=50))
    password = fields.Str(validate=validate.Length(min=8))
    isAdmin = fields.Bool(data_key="isAdmin")

class KnowledgeSourceSchema(Schema):
    id = fields.Int(dump_only=True)
    title = fields.Str(required=True)
    type = fields.Str(required=True)
    language = fields.Str(required=True)
    status = fields.Str(required=True)
    errorMessage = fields.Str(allow_none=True, data_key="errorMessage")
    createdAt = fields.DateTime(dump_only=True, data_key="createdAt")
    updatedAt = fields.DateTime(dump_only=True, data_key="updatedAt")

class KnowledgeSourceCreateUrlSchema(Schema):
    url = fields.Url(required=True)
    title = fields.Str(required=True, validate=validate.Length(min=1, max=255))
    language = fields.Str(load_default="en")

class RAGDecisionSummarySchema(Schema):
    answer = fields.Int(required=True)
    outOfDomain = fields.Int(required=True, data_key="outOfDomain")
    noHits = fields.Int(required=True, data_key="noHits")

class RAGQualitySummarySchema(Schema):
    inDomainRate = fields.Float(required=True, data_key="inDomainRate")
    fallbackRate = fields.Float(required=True, data_key="fallbackRate")
    errorRate = fields.Float(required=True, data_key="errorRate")
    avgDistance = fields.Float(required=True, data_key="avgDistance")
    avgContextsUsed = fields.Float(required=True, data_key="avgContextsUsed")

class RAGPerformanceSummarySchema(Schema):
    avgTotalTimeMs = fields.Float(required=True, data_key="avgTotalTimeMs")
    avgEmbeddingTimeMs = fields.Float(required=True, data_key="avgEmbeddingTimeMs")
    avgLlmTimeMs = fields.Float(required=True, data_key="avgLlmTimeMs")

class RAGTokenSummarySchema(Schema):
    totalUsed = fields.Int(required=True, data_key="totalUsed")
    avgPerQuery = fields.Float(required=True, data_key="avgPerQuery")

class RAGMetricsSummarySchema(Schema):
    period = fields.Str(required=True)
    totalQueries = fields.Int(required=True, data_key="totalQueries")
    summary = fields.Str(allow_none=True)
    decisions = fields.Nested(RAGDecisionSummarySchema(), allow_none=True)
    quality = fields.Nested(RAGQualitySummarySchema(), allow_none=True)
    performance = fields.Nested(RAGPerformanceSummarySchema(), allow_none=True)
    tokens = fields.Nested(RAGTokenSummarySchema(), allow_none=True)

class RAGMetricsQueryItemSchema(Schema):
    id = fields.Int(dump_only=True)
    userId = fields.Int(allow_none=True, data_key="userId")
    conversationId = fields.Int(allow_none=True, data_key="conversationId")
    language = fields.Str(required=True)
    safeMode = fields.Bool(required=True, data_key="safeMode")
    question = fields.Str(required=True)
    questionLength = fields.Int(required=True, data_key="questionLength")
    decision = fields.Str(required=True)
    inDomain = fields.Bool(required=True, data_key="inDomain")
    usedFallback = fields.Bool(required=True, data_key="usedFallback")
    contextsFound = fields.Int(required=True, data_key="contextsFound")
    contextsUsed = fields.Int(required=True, data_key="contextsUsed")
    threshold = fields.Float(allow_none=True)
    bestDistance = fields.Float(allow_none=True, data_key="bestDistance")
    totalTimeMs = fields.Int(required=True, data_key="totalTimeMs")
    embeddingTimeMs = fields.Int(required=True, data_key="embeddingTimeMs")
    llmTimeMs = fields.Int(allow_none=True, data_key="llmTimeMs")
    totalTokens = fields.Int(allow_none=True, data_key="totalTokens")
    errorOccurred = fields.Bool(required=True, data_key="errorOccurred")
    errorType = fields.Str(allow_none=True, data_key="errorType")
    createdAt = fields.DateTime(dump_only=True, data_key="createdAt")

class RAGQueryTextSchema(Schema):
    text = fields.Str(required=True)
    length = fields.Int(required=True)

class RAGAnswerSchema(Schema):
    text = fields.Str(required=True)
    length = fields.Int(required=True)
    usedFallback = fields.Bool(required=True, data_key="usedFallback")
    disclaimerAdded = fields.Bool(required=True, data_key="disclaimerAdded")

class RAGInfoSchema(Schema):
    threshold = fields.Float(allow_none=True)
    bestDistance = fields.Float(allow_none=True, data_key="bestDistance")
    contextsFound = fields.Int(required=True, data_key="contextsFound")
    contextsUsed = fields.Int(required=True, data_key="contextsUsed")
    inDomain = fields.Bool(required=True, data_key="inDomain")
    decision = fields.Str(required=True)

class RAGSourcesSchema(Schema):
    chunkIds = fields.List(fields.Int(), data_key="chunkIds")
    titles = fields.List(fields.Str(), data_key="titles")

class RAGPerformanceSchema(Schema):
    embeddingTimeMs = fields.Int(required=True, data_key="embeddingTimeMs")
    llmTimeMs = fields.Int(allow_none=True, data_key="llmTimeMs")
    totalTimeMs = fields.Int(required=True, data_key="totalTimeMs")

class RAGTokensSchema(Schema):
    prompt = fields.Int(allow_none=True)
    completion = fields.Int(allow_none=True)
    total = fields.Int(allow_none=True)

class RAGModelsSchema(Schema):
    embedding = fields.Str(required=True)
    embeddingDimension = fields.Int(allow_none=True, data_key="embeddingDimension")
    chat = fields.Str(allow_none=True)

class RAGErrorSchema(Schema):
    occurred = fields.Bool(required=True)
    type = fields.Str(allow_none=True)
    message = fields.Str(allow_none=True)

class RAGMetricsQueryDetailSchema(Schema):
    id = fields.Int(dump_only=True)
    userId = fields.Int(allow_none=True, data_key="userId")
    conversationId = fields.Int(allow_none=True, data_key="conversationId")
    language = fields.Str(required=True)
    safeMode = fields.Bool(required=True, data_key="safeMode")
    isNewConversation = fields.Bool(allow_none=True, data_key="isNewConversation")
    question = fields.Nested(RAGQueryTextSchema(), required=True)
    answer = fields.Nested(RAGAnswerSchema(), required=True)
    rag = fields.Nested(RAGInfoSchema(), required=True)
    sources = fields.Nested(RAGSourcesSchema(), required=True)
    performance = fields.Nested(RAGPerformanceSchema(), required=True)
    tokens = fields.Nested(RAGTokensSchema(), required=True)
    models = fields.Nested(RAGModelsSchema(), required=True)
    error = fields.Nested(RAGErrorSchema(), allow_none=True)
    createdAt = fields.DateTime(dump_only=True, data_key="createdAt")