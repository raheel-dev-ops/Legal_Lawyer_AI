# LegalAI Backend

Flask-based backend for LegalAI. Provides REST APIs, authentication, RAG/chat, admin tools, and background jobs.

## Features
- REST API under `/api/v1/*`
- Auth, users, rights, templates, pathways, checklists, drafts, chat, reminders, admin, content, lawyers, support
- Swagger UI at `/docs`
- Health checks at `/health` and `/api/v1/health`
- Celery worker for background tasks

## Tech Stack
- Python + Flask
- SQLAlchemy + Alembic (via Flask-Migrate)
- Celery + Redis
- JWT auth
- Swagger UI

## Project Structure (high level)
```
legalai-backend/
  app/                 # Flask app, routes, models, services
  migrations/          # Alembic migrations
  storage/             # Uploaded files (default local path)
  tests/               # Tests
  run.py               # Local dev entrypoint
  api/index.py         # Vercel entrypoint
  requirements.txt
  vercel.json
```

## Requirements
- Python 3.10+ (see `python_version`)
- Postgres (or any SQLAlchemy supported DB)
- Redis (for Celery + rate limiting)
- Qdrant (vector DB for multimodal RAG)

## Setup (Local)
1) Create venv and install deps:
```
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

2) Create `.env` in `legalai-backend/` (see env vars below).

3) Run migrations:
```
flask db upgrade
```

4) Start the API:
```
python run.py
```

API will be available at `http://127.0.0.1:5000`.

## Environment Variables
Required (minimum):
- `DATABASE_URL` (or `SQLALCHEMY_DATABASE_URI`)
- `SECRET_KEY`

Auth/JWT:
- `JWT_ACCESS_MIN` (default 15)
- `JWT_REFRESH_DAYS` (default 30)

Email/SMTP:
- `SMTP_HOST`
- `SMTP_PORT` (default 587)
- `MAIL_USE_TLS` (default True)
- `SMTP_USER`
- `SMTP_PASS`
- `EMAIL_FROM`
- `FRONTEND_VERIFY_URL`
- `FRONTEND_RESET_URL`
- `SUPPORT_INBOX_EMAIL`

Admin bootstrap:
- `SUPERADMIN_EMAIL`
- `SUPERADMIN_PASSWORD`

Storage & uploads:
- `STORAGE_BASE` (default `storage/uploads`)
- `MAX_UPLOAD_MB` (default 30)

AI / RAG:
- `CHAT_PROVIDER` (default `openai`)
- `CHAT_MODEL` (default `gpt-4o-mini`)
- `RAG_TOP_K` (default 5)
- `USER_API_KEYS_ENC_KEY` (required to encrypt per-user LLM API keys; generate with `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"`)

Multimodal RAG (Qdrant + ColPali + BGE):
- `QDRANT_URL` (or `QDRANT_HOST` + `QDRANT_PORT`)
- `QDRANT_TEXT_COLLECTION` (default `legal_text`)
- `QDRANT_PAGE_COLLECTION` (default `legal_pages`)
- `TEXT_EMBEDDING_PROVIDER` (default `local`)
- `TEXT_EMBEDDING_MODEL` (default `BAAI/bge-m3`)
- `TEXT_EMBEDDING_DEVICE` (default `cpu`)
- `IMAGE_EMBEDDING_MODEL` (default `vidore/colpali`)
- `IMAGE_EMBEDDING_DEVICE` (default `cpu`)
- `RERANKER_MODEL` (default `BAAI/bge-reranker-v2-m3`)
- `RERANKER_DEVICE` (default `cpu`)
- `RAG_TEXT_TOP_K`, `RAG_PAGE_TOP_K`, `RAG_CONTEXT_TEXT_K`, `RAG_CONTEXT_IMAGE_K`
- `RAG_TEXT_SCORE_THRESHOLD`, `RAG_PAGE_SCORE_THRESHOLD`
- `ENABLE_PAGE_RETRIEVAL` (default True)
- `VLM_ALWAYS`, `VLM_MAX_IMAGES`, `VLM_MAX_IMAGE_SIDE`

Push/Notifications (FCM HTTP v1):
- `FCM_PROJECT_ID`
- `FCM_SERVICE_ACCOUNT_FILE` (path to service account JSON)
- `FCM_SERVICE_ACCOUNT_JSON` (raw JSON string, optional alternative to file)

Redis / Celery / Rate limit:
- `REDIS_URL`
- `RATELIMIT_STORAGE_URI` (defaults to `REDIS_URL`)
- `RATELIMIT_DEFAULT` (default `120 per minute`)
- `CHAT_MEMORY_LIMIT` (default 10)

Other:
- `LAWYER_CATEGORIES_JSON`

## Health Check
```
GET /health
GET /api/v1/health
```
Both return `{ "status": "ok" }`.

## Swagger Docs
```
GET /docs
```

## Running Celery
Make sure Redis is running and `REDIS_URL` is set.
```
celery -A app.celery_worker.celery worker -l info
```

## Tests
```
pytest
```

## Deployment (Vercel)
This repo includes `vercel.json` and `api/index.py`.

1) In Vercel, set the project root to `legalai-backend`.
2) Set all required environment variables.
3) Deploy. Health check: `https://<your-vercel-domain>/health`.

## Notes
- If database env vars are missing, the app will error on startup.
- For production, configure a proper Postgres instance and Redis.
