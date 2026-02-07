from flask import Blueprint, request, jsonify, g, current_app
from werkzeug.exceptions import BadRequest, Unauthorized
from marshmallow import ValidationError
from ..services.auth_service import AuthService
from ..models.user import User
from ..extensions import db, limiter
from ._auth_guard import require_auth, safe_mode_on

from ..schemas.auth import (
    SignupSchema,
    LoginSchema,
    RefreshSchema,
    ForgotPasswordSchema,
    ResetPasswordSchema,
    ChangePasswordSchema,
    GoogleIdTokenSchema,
    GoogleCompleteSchema,
)
from ..utils.security import verify_password

bp = Blueprint("auth", __name__)

def _mask_email(email: str | None) -> str:
    if not email or "@" not in email:
        return "invalid-email"
    local, domain = email.split("@", 1)
    return f"{local[:1]}***@{domain}"


@bp.post("/signup")
@limiter.limit("10 per minute")
def signup():
    raw_data = request.get_json() or {}

    masked_email = _mask_email(raw_data.get("email"))
    current_app.logger.info(
        "Signup attempt initiated",
        extra={"email": masked_email}
    )
    
    schema = SignupSchema()
    
    try:
        data = schema.load(raw_data)
        current_app.logger.info("Schema validation passed")
    except ValidationError as e:
        current_app.logger.warning(
        "Signup schema validation failed",
        extra={"errors": e.messages}
    )
        return jsonify({
            "message": "Validation error",
            "errors": e.messages
        }), 400
    
    try:
        user = AuthService.create_user(data)
        current_app.logger.info(f"User created successfully: {user.id}")
    except ValueError as e:
        error_msg = str(e)
        current_app.logger.warning(f"Signup failed - Reason: {error_msg}")
        return jsonify({"message": error_msg}), 409

    access, refresh = AuthService.issue_tokens(user)
    return jsonify({
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "isEmailVerified": user.is_email_verified
        },
        "accessToken": access,
        "refreshToken": refresh
    }), 201

@bp.post("/login")
@limiter.limit("10 per minute")
def login():
    data = LoginSchema().load(request.get_json() or {})
    invalid = (jsonify({"message": "Invalid email or password"}), 401)

    user = User.query.filter_by(email=data["email"].lower()).first()

    if user is None or getattr(user, "is_deleted", False):
        return invalid

    if not verify_password(data["password"], user.password_hash):
        return invalid

    if not user.is_email_verified:
        return jsonify({"message": "Email not verified"}), 403

    access, refresh = AuthService.issue_tokens(user)
    return jsonify({
        "accessToken": access,
        "refreshToken": refresh,
        "isEmailVerified": user.is_email_verified
    })

@bp.post("/refresh")
def refresh():
    data = RefreshSchema().load(request.get_json() or {})
    tokens = AuthService.refresh_tokens(data["refreshToken"])
    if not tokens:
        raise Unauthorized("Invalid refresh token")
    access, refresh = tokens
    return jsonify({"accessToken": access, "refreshToken": refresh})

@bp.get("/verify-email")
@limiter.limit("30 per hour")
def verify_email():
    token = request.args.get("token")
    if not token:
        raise BadRequest("Missing token")
    ok = AuthService.verify_email(token)
    return jsonify({"verified": ok})

@bp.post("/forgot-password")
@limiter.limit("5 per minute")
def forgot_password():
    data = ForgotPasswordSchema().load(request.get_json() or {})
    AuthService.request_password_reset(data["email"].lower())
    return jsonify({"ok": True})

@bp.post("/reset-password")
@limiter.limit("5 per minute")
def reset_password():
    data = ResetPasswordSchema().load(request.get_json() or {})
    ok = AuthService.reset_password(data["token"], data["newPassword"])
    if not ok:
        raise BadRequest("Invalid or expired token")
    return jsonify({"ok": True})

@bp.post("/change-password")
@require_auth()
def change_password():
    if safe_mode_on():
        return jsonify({"ok": False, "message": "Safe mode"}), 403

    data = ChangePasswordSchema().load(request.get_json() or {})
    ok, err = AuthService.change_password(
        g.user,
        data["currentPassword"],
        data["newPassword"],
    )
    if not ok:
        return jsonify({"message": err}), 400

    access, refresh = AuthService.issue_tokens(g.user)
    return jsonify({
        "message": "Password updated",
        "accessToken": access,
        "refreshToken": refresh,
    })


@bp.post("/google")
@limiter.limit("10 per minute")
def google_login():
    data = GoogleIdTokenSchema().load(request.get_json() or {})
    try:
        payload = AuthService.verify_google_id_token(data["idToken"])
    except ValueError:
        raise Unauthorized("Invalid Google token")

    email = (payload.get("email") or "").strip().lower()
    name = (payload.get("name") or "").strip()
    google_sub = payload.get("sub")

    if not email or not google_sub:
        raise Unauthorized("Invalid Google token")

    user = User.query.filter_by(email=email).first()
    if user:
        if getattr(user, "is_deleted", False):
            raise Unauthorized("User not found")
        if user.google_sub and user.google_sub != google_sub:
            return jsonify({"message": "Google account already linked to another user"}), 409
        if not user.google_sub:
            user.google_sub = google_sub
        if not user.is_email_verified:
            user.is_email_verified = True
        db.session.commit()
        access, refresh = AuthService.issue_tokens(user)
        return jsonify({
            "accessToken": access,
            "refreshToken": refresh,
            "isEmailVerified": True,
        })

    google_token = AuthService.issue_google_preauth({
        "sub": google_sub,
        "email": email,
        "name": name,
    })
    return jsonify({
        "needsProfile": True,
        "googleToken": google_token,
        "prefill": {
            "email": email,
            "name": name,
        },
    })


@bp.post("/google/complete")
@limiter.limit("10 per minute")
def google_complete():
    if safe_mode_on():
        return jsonify({"ok": False, "message": "Safe mode"}), 403

    data = GoogleCompleteSchema().load(request.get_json() or {})
    payload = AuthService.verify_google_preauth(data["googleToken"])
    if not payload:
        raise Unauthorized("Invalid Google token")

    email = (payload.get("email") or "").strip().lower()
    google_sub = payload.get("sub")
    token_name = (payload.get("name") or "").strip()
    if not email or not google_sub:
        raise Unauthorized("Invalid Google token")

    if data.get("email") and data.get("email").strip().lower() != email:
        raise BadRequest("Email mismatch")

    name = (data.get("name") or token_name).strip()
    if not name:
        raise BadRequest("Name is required")

    existing = User.query.filter_by(email=email).first()
    if existing:
        if getattr(existing, "is_deleted", False):
            raise Unauthorized("User not found")
        if existing.google_sub and existing.google_sub != google_sub:
            return jsonify({"message": "Google account already linked to another user"}), 409
        if not existing.google_sub:
            existing.google_sub = google_sub
        if not existing.is_email_verified:
            existing.is_email_verified = True
        db.session.commit()
        access, refresh = AuthService.issue_tokens(existing)
        return jsonify({
            "accessToken": access,
            "refreshToken": refresh,
            "isEmailVerified": True,
        })

    try:
        user = AuthService.create_google_user(data, google_sub, email, name)
    except ValueError as e:
        return jsonify({"message": str(e)}), 409

    access, refresh = AuthService.issue_tokens(user)
    return jsonify({
        "accessToken": access,
        "refreshToken": refresh,
        "isEmailVerified": True,
    })
    
