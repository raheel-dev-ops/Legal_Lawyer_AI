from dotenv import load_dotenv
import os
from datetime import timedelta

load_dotenv()

class Config:
    ENV = os.getenv("FLASK_ENV", "production")
    DEBUG = ENV == "development"

    SECRET_KEY = os.getenv("SECRET_KEY", "change-me")
    DATABASE_URL = os.getenv("DATABASE_URL") or os.getenv("SQLALCHEMY_DATABASE_URI")
    SQLALCHEMY_DATABASE_URI = DATABASE_URL
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    JWT_ACCESS_EXPIRES = timedelta(minutes=int(os.getenv("JWT_ACCESS_MIN", "15")))
    JWT_REFRESH_EXPIRES = timedelta(days=int(os.getenv("JWT_REFRESH_DAYS", "30")))
    JWT_ALGORITHM = "HS256"
    GOOGLE_CLIENT_ID_ANDROID = os.getenv("GOOGLE_CLIENT_ID_ANDROID")
    GOOGLE_CLIENT_ID_WEB = os.getenv("GOOGLE_CLIENT_ID_WEB")
    GOOGLE_PREAUTH_EXPIRES = timedelta(minutes=int(os.getenv("GOOGLE_PREAUTH_MIN", "15")))
    USER_API_KEYS_ENC_KEY = os.getenv("USER_API_KEYS_ENC_KEY")

    SMTP_HOST = os.getenv("SMTP_HOST")
    SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
    MAIL_USE_TLS = os.getenv("MAIL_USE_TLS", "True").lower() == "true"
    SMTP_USER = os.getenv("SMTP_USER")
    SMTP_PASS = os.getenv("SMTP_PASS")
    EMAIL_FROM = os.getenv("EMAIL_FROM")
    FRONTEND_VERIFY_URL = os.getenv("FRONTEND_VERIFY_URL")
    FRONTEND_RESET_URL = os.getenv("FRONTEND_RESET_URL")
    SUPPORT_INBOX_EMAIL = os.getenv("SUPPORT_INBOX_EMAIL")
    LAWYER_CATEGORIES_JSON = os.getenv("LAWYER_CATEGORIES_JSON")
    
    SUPERADMIN_EMAIL = os.getenv("SUPERADMIN_EMAIL")
    SUPERADMIN_PASSWORD = os.getenv("SUPERADMIN_PASSWORD")

    STORAGE_BASE = os.getenv("STORAGE_BASE", os.path.abspath("storage/uploads"))
    MAX_UPLOAD_MB = int(os.getenv("MAX_UPLOAD_MB", "30"))
    ALLOWED_EXTS = {
        "txt", "csv", "tsv", "json",
        "pdf", "docx",
        "xlsx",
        "png", "jpg", "jpeg", "svg",
    }

    QDRANT_URL = os.getenv("QDRANT_URL")
    QDRANT_HOST = os.getenv("QDRANT_HOST", "localhost")
    QDRANT_PORT = int(os.getenv("QDRANT_PORT", "6333"))
    QDRANT_API_KEY = os.getenv("QDRANT_API_KEY")
    QDRANT_TIMEOUT = int(os.getenv("QDRANT_TIMEOUT", "30"))
    QDRANT_TEXT_COLLECTION = os.getenv("QDRANT_TEXT_COLLECTION", "legal_text")
    QDRANT_PAGE_COLLECTION = os.getenv("QDRANT_PAGE_COLLECTION", "legal_pages")

    TEXT_EMBEDDING_PROVIDER = os.getenv("TEXT_EMBEDDING_PROVIDER", "local")
    TEXT_EMBEDDING_MODEL = os.getenv("TEXT_EMBEDDING_MODEL", "BAAI/bge-m3")
    TEXT_EMBEDDING_DIMENSION = int(os.getenv("TEXT_EMBEDDING_DIMENSION", "0") or 0)
    TEXT_EMBEDDING_DEVICE = os.getenv("TEXT_EMBEDDING_DEVICE", "cpu")
    TEXT_EMBEDDING_BATCH_SIZE = int(os.getenv("TEXT_EMBEDDING_BATCH_SIZE", "32"))

    IMAGE_EMBEDDING_MODEL = os.getenv("IMAGE_EMBEDDING_MODEL", "vidore/colpali")
    IMAGE_EMBEDDING_DIMENSION = int(os.getenv("IMAGE_EMBEDDING_DIMENSION", "0") or 0)
    IMAGE_EMBEDDING_DEVICE = os.getenv("IMAGE_EMBEDDING_DEVICE", "cpu")
    IMAGE_EMBEDDING_BATCH_SIZE = int(os.getenv("IMAGE_EMBEDDING_BATCH_SIZE", "8"))

    RERANKER_MODEL = os.getenv("RERANKER_MODEL", "BAAI/bge-reranker-v2-m3")
    RERANKER_DEVICE = os.getenv("RERANKER_DEVICE", "cpu")
    RERANKER_CANDIDATES = int(os.getenv("RERANKER_CANDIDATES", "20"))
    RERANKER_MAX_LENGTH = int(os.getenv("RERANKER_MAX_LENGTH", "512"))


    EMBEDDING_PROVIDER = os.getenv("EMBEDDING_PROVIDER", "openai") 
    EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "text-embedding-3-large")
    CHAT_PROVIDER = os.getenv("CHAT_PROVIDER", "openai")
    CHAT_MODEL = os.getenv("CHAT_MODEL", "gpt-4o-mini")
    CHAT_MODEL_OPENAI = os.getenv("CHAT_MODEL_OPENAI", "gpt-4o-mini")
    CHAT_MODEL_GROQ = os.getenv("CHAT_MODEL_GROQ", "llama-3.1-8b-instant")
    CHAT_MODEL_OPENROUTER = os.getenv("CHAT_MODEL_OPENROUTER") or CHAT_MODEL
    CHAT_PROVIDER_FALLBACKS = os.getenv("CHAT_PROVIDER_FALLBACKS", "")
    RAG_TOP_K = int(os.getenv("RAG_TOP_K", "5"))
    RAG_TEXT_TOP_K = int(os.getenv("RAG_TEXT_TOP_K", "12"))
    RAG_PAGE_TOP_K = int(os.getenv("RAG_PAGE_TOP_K", "6"))
    RAG_CONTEXT_TEXT_K = int(os.getenv("RAG_CONTEXT_TEXT_K", "5"))
    RAG_CONTEXT_IMAGE_K = int(os.getenv("RAG_CONTEXT_IMAGE_K", "3"))
    RAG_TEXT_SCORE_THRESHOLD = float(os.getenv("RAG_TEXT_SCORE_THRESHOLD", "0.2"))
    RAG_PAGE_SCORE_THRESHOLD = float(os.getenv("RAG_PAGE_SCORE_THRESHOLD", "0.2"))
    ENABLE_PAGE_RETRIEVAL = os.getenv("ENABLE_PAGE_RETRIEVAL", "True").lower() == "true"

    VLM_ALWAYS = os.getenv("VLM_ALWAYS", "True").lower() == "true"
    VLM_MAX_IMAGES = int(os.getenv("VLM_MAX_IMAGES", "3"))
    VLM_MAX_IMAGE_SIDE = int(os.getenv("VLM_MAX_IMAGE_SIDE", "1280"))

    PDF_RENDER_DPI = int(os.getenv("PDF_RENDER_DPI", "150"))
    MAX_PAGES_PER_DOC = int(os.getenv("MAX_PAGES_PER_DOC", "80"))
    MAX_PAGE_IMAGE_SIDE = int(os.getenv("MAX_PAGE_IMAGE_SIDE", "1600"))
    ENABLE_OCR = os.getenv("ENABLE_OCR", "False").lower() == "true"

    FCM_PROJECT_ID = os.getenv("FCM_PROJECT_ID")
    FCM_SERVICE_ACCOUNT_FILE = os.getenv("FCM_SERVICE_ACCOUNT_FILE")
    FCM_SERVICE_ACCOUNT_JSON = os.getenv("FCM_SERVICE_ACCOUNT_JSON")

    REDIS_URL = os.getenv("REDIS_URL")
    CELERY_BROKER_URL = REDIS_URL
    CELERY_RESULT_BACKEND = REDIS_URL

    RATELIMIT_STORAGE_URI = os.getenv("RATELIMIT_STORAGE_URI") or REDIS_URL
    RATELIMIT_DEFAULT = os.getenv("RATELIMIT_DEFAULT", "120 per minute")
    RATELIMIT_HEADERS_ENABLED = True
    CHAT_MEMORY_LIMIT = int(os.getenv("CHAT_MEMORY_LIMIT", "10"))
    CHAT_ASYNC_ENABLED = os.getenv("CHAT_ASYNC_ENABLED", "True").lower() == "true"
    CHAT_ASYNC_MAX_WAIT_SEC = int(os.getenv("CHAT_ASYNC_MAX_WAIT_SEC", "25"))
    
    EMBEDDING_DIMENSION = int(os.getenv("EMBEDDING_DIMENSION", "3072"))
    EMBEDDING_MODEL_NAME = os.getenv("EMBEDDING_MODEL", "text-embedding-3-large")
