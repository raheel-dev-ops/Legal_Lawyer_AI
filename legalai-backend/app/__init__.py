from flask import Flask, jsonify, send_from_directory
from .config import Config
from .extensions import db, ma, migrate, limiter
from .tasks.celery_app import init_celery
from .utils.errors import register_error_handlers
from .models.user import User
from .utils.security import hash_password
from dotenv import load_dotenv
from sqlalchemy.exc import OperationalError, ProgrammingError
from flask_cors import CORS
from .utils.logging_config import setup_logging
from flask_swagger_ui import get_swaggerui_blueprint
import os

from .api import (
    auth_routes,
    user_routes,
    rights_routes,
    templates_routes,
    pathways_routes,
    checklists_routes,
    drafts_routes,
    chat_routes,
    reminders_routes,
    admin_routes,
    content_routes,
    lawyers_routes,
    support_routes,
    emergency_contacts_routes,
    notifications_routes,
)


def create_app():
    load_dotenv()
    app = Flask(__name__)
    app.config.from_object(Config)
    setup_logging(app)
    if not app.config.get("SQLALCHEMY_DATABASE_URI"):
        raise RuntimeError(
            "Database is not configured. Set DATABASE_URL (preferred) or "
            "SQLALCHEMY_DATABASE_URI in your environment/.env."
        )
    cors_origins = [
        r"http://localhost:\d+",
        r"http://127\.0\.0\.1:\d+",
        "https://gowaned-beckham-unlawful.ngrok-free.dev",
    ]
    CORS(
        app,
        resources={
            r"/api/.*": {"origins": cors_origins},
            r"/uploads/.*": {"origins": cors_origins},
        },
        supports_credentials=False,
        allow_headers=[
            "Content-Type",
            "Authorization",
            "X-Safe-Mode",
            "ngrok-skip-browser-warning",
        ],
        methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        max_age=3600,
    )
    db.init_app(app)
    ma.init_app(app)
    migrate.init_app(app, db)
    limiter.init_app(app)
    init_celery(app)

    SWAGGER_URL = "/docs"
    API_SPEC_URL = "/static/openapi.yaml"

    swaggerui_blueprint = get_swaggerui_blueprint(
        SWAGGER_URL,
        API_SPEC_URL,
        config={
            "app_name": "Legal Lawyer AI API",
        },
    )
    app.register_blueprint(swaggerui_blueprint, url_prefix=SWAGGER_URL)

    @app.get("/static/<path:filename>")
    def swagger_static(filename):
        return send_from_directory("static", filename)

    @app.get("/uploads/<path:filename>")
    def uploads_static(filename):
        response = send_from_directory(
            app.config["STORAGE_BASE"],
            filename,
            max_age=31536000,
        )
        ext = os.path.splitext(filename)[1].lower()
        if ext in {".jpg", ".jpeg", ".png", ".gif", ".webp"}:
            response.cache_control.public = True
            response.cache_control.max_age = 31536000
            response.cache_control.immutable = True
            response.cache_control.no_cache = False
            response.cache_control.no_store = False
            response.cache_control.must_revalidate = False
        return response

    app.register_blueprint(auth_routes.bp, url_prefix="/api/v1/auth")
    app.register_blueprint(user_routes.bp, url_prefix="/api/v1/users")
    app.register_blueprint(rights_routes.bp, url_prefix="/api/v1/rights")
    app.register_blueprint(templates_routes.bp, url_prefix="/api/v1/templates")
    app.register_blueprint(pathways_routes.bp, url_prefix="/api/v1/pathways")
    app.register_blueprint(checklists_routes.bp, url_prefix="/api/v1/checklists")
    app.register_blueprint(drafts_routes.bp, url_prefix="/api/v1/drafts")
    app.register_blueprint(chat_routes.bp, url_prefix="/api/v1/chat")
    app.register_blueprint(reminders_routes.bp, url_prefix="/api/v1/reminders")
    app.register_blueprint(notifications_routes.bp, url_prefix="/api/v1/notifications")
    app.register_blueprint(admin_routes.bp, url_prefix="/api/v1/admin")
    app.register_blueprint(content_routes.bp, url_prefix="/api/v1/content")
    app.register_blueprint(lawyers_routes.bp, url_prefix="/api/v1/lawyers")
    app.register_blueprint(support_routes.bp, url_prefix="/api/v1/support")
    app.register_blueprint(
        emergency_contacts_routes.bp, url_prefix="/api/v1/users/me/emergency-contacts"
    )

    register_error_handlers(app)

    @app.get("/api/v1/health")
    def health():
        return jsonify({"status": "ok"})

    @app.get("/health")
    def health_root():
        return jsonify({"status": "ok"})

    _ensure_superadmin(app)
    return app


def _ensure_superadmin(app):
    with app.app_context():
        email = app.config.get("SUPERADMIN_EMAIL")
        pw = app.config.get("SUPERADMIN_PASSWORD")
        if not email or not pw:
            return
        try:
            existing = User.query.filter_by(email=email.lower()).first()
        except (OperationalError, ProgrammingError):
            return

        if existing:
            existing.is_admin = True
            db.session.commit()
            return
        sa = User(
            name="Super Admin",
            email=email.lower(),
            phone="0000000000",
            cnic="00000-0000000-0",
            password_hash=hash_password(pw),
            is_admin=True,
            is_email_verified=True,
        )
        db.session.add(sa)
        db.session.commit()
