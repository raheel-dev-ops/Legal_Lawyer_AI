# LegalAI Project Setup Guide (Windows Only)

This is the authoritative setup guide for this repository.
Stack: Flask API + Celery workers + Flutter app (Android device and Web).

## Quick Start (Local Dev)
1) Install prerequisites below (Python, Git, Docker, PostgreSQL, Flutter, Android Studio, Chrome).
2) Setup PostgreSQL + pgvector.
3) Start Redis (Docker).
4) Configure `legalai-backend\.env`.
5) Run backend (`python run.py`).
6) Run frontend (Android or Web).

## Documentation & References
- Backend details: `legalai-backend\README.md`
- Frontend details: `legalai-frontend\README.md`
- OpenAPI spec file: `legalai-backend\app\static\openapi.yaml` (Swagger UI at `/docs`)
- PRD: `PRD-notifications.md`
- RAG test set: `RAG_TESTING_QUESTIONS.pdf`

## Project Structure (Top Level)
- `legalai-backend\`: Flask API, Celery, DB, migrations
- `legalai-frontend\`: Flutter app (Android + Web)
- `AGENTS.md`: repo rules for assistants

## What This Repo Contains
- Backend: Flask, SQLAlchemy, Alembic migrations, Celery, Redis, PostgreSQL, pgvector
- Frontend: Flutter (Android and Web)

## Prerequisites (Install Once)
1) Python 3.10.x
   - https://www.python.org/downloads/release/python-310/
2) Git
   - https://git-scm.com/download/win
3) Docker Desktop (for Redis container)
   - https://www.docker.com/products/docker-desktop/
4) PostgreSQL 17 + pgAdmin 4
   - https://www.postgresql.org/download/windows/
5) Flutter SDK (stable)
   - https://docs.flutter.dev/get-started/install/windows
6) Android Studio (SDK + platform-tools)
   - https://developer.android.com/studio
7) Google Chrome (for Web)
   - https://www.google.com/chrome/

Verify installs (PowerShell):
```bash
python --version
git --version
docker --version
flutter --version
```

## Repository Setup
If you already have the repo locally, skip this step.
```bash
git clone <REPO_URL>
cd legal_ai_lawyer_v3
```

## PostgreSQL 17 Setup (pgAdmin)
1) Install PostgreSQL 17 with pgAdmin 4.
2) Open pgAdmin 4 and connect to your local server.
3) Create a database user and database.
   - Choose your own values (user, password, database name, port).
4) Note these values because they must match your `.env` file:
   - Host, Port, Database name, Username, Password

## pgvector Installation (PostgreSQL 17, Windows)
This project uses pgvector. You must install the extension before migrations.

1) Download the PostgreSQL 17 Windows build from GitHub:
   - https://github.com/andreiramani/pgvector_pgsql_windows/releases
2) Choose the Windows x64 artifact for PostgreSQL 17.
3) Extract the archive.
4) Copy files into your PostgreSQL 17 installation folder:
   - Copy `pgvector.dll` to:
     `C:\Program Files\PostgreSQL\17\lib\`
   - Copy `vector.control` and all `vector--*.sql` files to:
     `C:\Program Files\PostgreSQL\17\share\extension\`
5) Restart PostgreSQL service:
   - Open `services.msc`
   - Restart `postgresql-x64-17`
6) Enable the extension inside your database:
   - Open pgAdmin Query Tool for your database and run:
```sql
CREATE EXTENSION IF NOT EXISTS vector;
```
7) Verify:
```sql
SELECT extname FROM pg_extension WHERE extname = 'vector';
```

## Redis Setup (Docker)
Run Redis in a container named `Redis`:
```bash
docker pull redis
docker run -d --name Redis -p 6379:6379 redis
docker ps
```

## Qdrant Setup (Optional, for Multimodal RAG)
If you plan to use page/image retrieval, run Qdrant and set `QDRANT_URL`:
```bash
docker pull qdrant/qdrant:v1.9.5
docker run -d --name Qdrant -p 6333:6333 qdrant/qdrant:v1.9.5
```
```
QDRANT_URL=http://localhost:6333
```

## Backend Setup (Flask)
From the repo root:
```bash
cd legalai-backend
```

### 1) Configure Environment Variables
Open `legalai-backend\.env` and set real values. These are mandatory.

Database (must match pgAdmin):
```
DATABASE_URL=postgresql://<db_user>:<db_password>@localhost:<db_port>/<db_name>
SQLALCHEMY_DATABASE_URI=postgresql://<db_user>:<db_password>@localhost:<db_port>/<db_name>
```

Core:
```
FLASK_ENV=development
SECRET_KEY=<set_a_strong_secret>
```

SMTP (Gmail, mandatory):
```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
MAIL_USE_TLS=True
SMTP_USER=<your_gmail_address>
SMTP_PASS=<your_gmail_app_password>
EMAIL_FROM=<your_gmail_address>
SUPPORT_INBOX_EMAIL=<support_inbox_address>
FRONTEND_VERIFY_URL=<your_frontend_verify_url>
FRONTEND_RESET_URL=<your_frontend_reset_url>
```

Superadmin (created on startup if not present):
```
SUPERADMIN_EMAIL=<admin_email>
SUPERADMIN_PASSWORD=<admin_password>
```

Redis:
```
REDIS_URL=redis://localhost:6379/0
```

LLM Providers (GroqCloud chat, OpenAI embeddings):
```
CHAT_PROVIDER=groq
CHAT_MODEL=<your_groq_chat_model>
GROQ_API_KEY=<your_groq_api_key>

EMBEDDING_PROVIDER=openai
EMBEDDING_MODEL=text-embedding-3-large
EMBEDDING_DIMENSION=3072
OPENAI_API_KEY=<your_openai_api_key>
```

Multimodal RAG (Qdrant + ColPali + BGE + reranker):
```
# Vector DB
QDRANT_URL=http://localhost:6333
QDRANT_TEXT_COLLECTION=legal_text
QDRANT_PAGE_COLLECTION=legal_pages

# Text retriever
TEXT_EMBEDDING_PROVIDER=local
TEXT_EMBEDDING_MODEL=BAAI/bge-m3
TEXT_EMBEDDING_DEVICE=cpu

# Page retriever (OCR-less)
IMAGE_EMBEDDING_MODEL=vidore/colpali
IMAGE_EMBEDDING_DEVICE=cpu

# Reranker
RERANKER_MODEL=BAAI/bge-reranker-v2-m3
RERANKER_DEVICE=cpu

# RAG tuning
RAG_TEXT_TOP_K=12
RAG_PAGE_TOP_K=6
RAG_CONTEXT_TEXT_K=5
RAG_CONTEXT_IMAGE_K=3
RAG_TEXT_SCORE_THRESHOLD=0.2
RAG_PAGE_SCORE_THRESHOLD=0.2
ENABLE_PAGE_RETRIEVAL=True

# VLM answering (OpenAI-compatible server hosting Qwen2.5-VL)
VLM_ALWAYS=True
VLM_MAX_IMAGES=3
VLM_MAX_IMAGE_SIDE=1280
```

Optional providers supported by the backend:
- Chat providers: openai, groq, openrouter, deepseek, grok, anthropic
  - Keys: OPENAI_API_KEY, GROQ_API_KEY, OPENROUTER_API_KEY, DEEPSEEK_API_KEY, GROK_API_KEY, ANTHROPIC_API_KEY
- Embedding providers: openai, openrouter, deepseek, grok, groq
  - Keys: OPENAI_API_KEY, OPENROUTER_API_KEY, DEEPSEEK_API_KEY, GROQ_API_KEY, GROK_API_KEY
- Base URLs (optional): OPENAI_BASE_URL, OPENROUTER_BASE_URL, GROQ_BASE_URL

### 2) Create Virtual Environment
```bash
python -m venv venv
```
If you have multiple Python versions:
```bash
py -3.10 -m venv venv
```

Activate:
```bash
venv\Scripts\activate
```

### 3) Install Dependencies
```bash
pip install -r requirements.txt
```

### 4) Run Migrations
```bash
python -m flask --app run.py db upgrade
```

### 5) Start Backend API
```bash
python run.py
```
API health check:
```
http://127.0.0.1:5000/api/v1/health
```
Swagger UI:
```
http://127.0.0.1:5000/docs
```

## Celery Worker and Beat
Keep Redis running before starting Celery.

Worker:
```bash
cd legalai-backend
venv\Scripts\activate
celery -A app.celery_worker:celery worker --loglevel=info --pool=solo
```

Beat:
```bash
cd legalai-backend
venv\Scripts\activate
celery -A app.celery_worker:celery beat --loglevel=info
```

## Frontend Setup (Flutter)
From repo root:
```bash
cd legalai-frontend
```

### 1) Flutter Dependencies
```bash
flutter doctor
flutter pub get
```

### 2) API Base URL
Edit:
```
legalai-frontend\lib\core\constants\app_constants.dart
```

For Android device (physical):
```
static const String apiBaseUrlDev = 'http://<YOUR_PC_IP>:5000/api/v1';
```

For Web (Chrome):
```
static const String apiBaseUrlDev = 'http://127.0.0.1:5000/api/v1';
```

When switching between Android device and Web, update this value.

### Flutter Runtime Config (Recommended)
Create `legalai-frontend/env.json` from `legalai-frontend/env.example.json` and set:
- `API_BASE_URL`
- `GOOGLE_SERVER_CLIENT_ID` (Android; can be same as web client ID)
- `GOOGLE_WEB_CLIENT_ID` (Web)

**Note:** Flutter does **not** read `legalai-backend/.env`. You must pass values via
`--dart-define-from-file` or hardcode defaults in `AppConstants`.

For Android, use the web client ID from:
`legalai-frontend/android/app/google-services.json` → `oauth_client` with `client_type: 3`.

## Run on Android Device
1) Enable Developer Options and USB Debugging on your phone.
2) Connect the device via USB.
3) Verify the device is detected:
```bash
flutter devices
```
  4) Run from repo root:
  ```bash
  flutter run -d BM4DLN --dart-define-from-file=legalai-frontend/env.json
  ```
  Or from `legalai-frontend/`:
  ```bash
  flutter run -d BM4DLNN --dart-define-from-file=env.json
  ```

## Run on Web (Chrome)
  From repo root:
  ```bash
  flutter run -d chrome --dart-define-from-file=legalai-frontend/env.json
  ```
  Or from `legalai-frontend/`:
  ```bash
  flutter run -d chrome --dart-define-from-file=env.json
  ```

## Ngrok Setup (Expose Local API for External Devices)
Use this when your Android device is NOT on the same Wi‑Fi/LAN or you need a public HTTPS URL.

### 1) Create Ngrok Account
1) Go to ngrok.com and sign up (free plan is fine).
2) Copy your **Auth Token** from the dashboard.

### 2) Install Ngrok (Windows)
1) Download the Windows 64‑bit ZIP from ngrok.com/download.
2) Extract `ngrok.exe`.
3) Move `ngrok.exe` to a folder on your PATH (recommended):
   - `C:\Windows\System32\` or
   - `C:\Program Files\ngrok\` (then add this folder to PATH)
4) Verify:
```bash
ngrok version
```

### 3) Connect Your Auth Token
```bash
ngrok config add-authtoken <YOUR_NGROK_AUTH_TOKEN>
```

### 4) Start Ngrok Tunnel (Backend must be running)
In a new terminal:
```bash
ngrok http 5000
```
You will get a **Forwarding URL** like:
```
https://abc123.ngrok-free.app -> http://localhost:5000
```

### 5) Update Flutter API Base URL
Update `legalai-frontend\lib\core\constants\app_constants.dart`:
```
static const String apiBaseUrlDev = 'https://abc123.ngrok-free.app/api/v1';
```

### 6) Update Backend Email Links (If using email flows)
If your app sends verification/reset emails, set these in `legalai-backend\.env`:
```
FRONTEND_VERIFY_URL=<your_frontend_verify_url>
FRONTEND_RESET_URL=<your_frontend_reset_url>
```
If you host frontend via Ngrok too, use its HTTPS URL.

### Notes
- Free Ngrok URLs change each time you restart the tunnel.
- Keep the Ngrok terminal open while testing.

## Recommended Startup Order
1) Redis container
2) Backend API
3) (Optional) Ngrok tunnel (if using public URL)
4) Celery worker
5) Celery beat
6) Flutter app (Android or Web)

## Common Checks
- If migrations fail with vector errors, verify pgvector installation and `CREATE EXTENSION vector;`
- If Celery fails to connect, verify the Redis container is running and `REDIS_URL` is correct
- If Android device cannot reach the API, confirm the PC IP in `apiBaseUrlDev` and that the device and PC are on the same network

## Optional Tests
Backend:
```bash
cd legalai-backend
venv\Scripts\activate
pytest
```

Frontend:
```bash
cd legalai-frontend
flutter test
```

## Contributing
- Keep secrets out of git; use local `.env` files only.
- Run the smallest relevant test (see Optional Tests).

## License
Not specified in this repository.
