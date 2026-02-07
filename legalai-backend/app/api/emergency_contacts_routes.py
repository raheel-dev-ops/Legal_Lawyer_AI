import re
from flask import Blueprint, request, jsonify, g, current_app
from werkzeug.exceptions import BadRequest, Forbidden
from sqlalchemy.exc import IntegrityError
from ._auth_guard import require_auth, safe_mode_on
from ..extensions import db
from ..models.emergency_contact import EmergencyContact
from ..schemas.emergency_contacts import (
    EmergencyContactCreateSchema,
    EmergencyContactUpdateSchema,
    EmergencyContactSchema,
)


bp = Blueprint("emergency_contacts", __name__)


def _digits(value: str) -> str:
    return re.sub(r"\D", "", value or "")


def _normalize_pk_phone(country_code: str, phone: str) -> tuple[str, str]:
    cc_digits = _digits(country_code)
    phone_digits = _digits(phone)

    if phone_digits.startswith("92"):
        phone_digits = phone_digits[2:]
    elif phone_digits.startswith("0"):
        phone_digits = phone_digits[1:]

    if cc_digits in ("", "92"):
        cc = "+92"
    else:
        raise BadRequest("Invalid countryCode")

    if len(phone_digits) != 10 or not phone_digits.startswith("3"):
        raise BadRequest("Invalid phone")

    return cc, phone_digits


def _mask_phone(phone: str) -> str:
    if not phone:
        return ""
    return f"***{phone[-2:]}"


@bp.get("")
@require_auth()
def list_contacts():
    items = EmergencyContact.query.filter_by(user_id=g.user.id).order_by(EmergencyContact.created_at.desc()).all()
    return jsonify(EmergencyContactSchema(many=True).dump(items))


@bp.post("")
@require_auth()
def create_contact():
    if safe_mode_on():
        raise Forbidden("Safe mode enabled")

    data = EmergencyContactCreateSchema().load(request.get_json() or {})
    count = EmergencyContact.query.filter_by(user_id=g.user.id).count()
    if count >= 5:
        raise BadRequest("Contact limit reached")

    cc, phone = _normalize_pk_phone(data.get("countryCode"), data.get("phone"))
    contact = EmergencyContact(
        user_id=g.user.id,
        name=data["name"].strip(),
        relation=data["relation"].strip(),
        country_code=cc,
        phone=phone,
        is_primary=bool(data.get("isPrimary", False)),
    )
    db.session.add(contact)
    db.session.flush()
    if contact.is_primary:
        EmergencyContact.query.filter(
            EmergencyContact.user_id == g.user.id,
            EmergencyContact.id != contact.id,
        ).update({"is_primary": False})
    try:
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        raise BadRequest("Duplicate contact")

    current_app.logger.info(
        "EmergencyContact created userId=%s contactId=%s primary=%s phone=%s",
        g.user.id, contact.id, contact.is_primary, _mask_phone(contact.phone)
    )
    return jsonify(EmergencyContactSchema().dump(contact)), 201


@bp.put("/<int:cid>")
@require_auth()
def update_contact(cid: int):
    if safe_mode_on():
        raise Forbidden("Safe mode enabled")

    contact = EmergencyContact.query.get_or_404(cid)
    if contact.user_id != g.user.id:
        raise Forbidden("Not yours")

    data = EmergencyContactUpdateSchema().load(request.get_json() or {})

    if "name" in data:
        contact.name = data["name"].strip()
    if "relation" in data:
        contact.relation = data["relation"].strip()
    if "phone" in data or "countryCode" in data:
        cc, phone = _normalize_pk_phone(
            data.get("countryCode", contact.country_code),
            data.get("phone", contact.phone),
        )
        contact.country_code = cc
        contact.phone = phone
    if "isPrimary" in data:
        contact.is_primary = bool(data["isPrimary"])

    if contact.is_primary:
        EmergencyContact.query.filter(
            EmergencyContact.user_id == g.user.id,
            EmergencyContact.id != contact.id,
        ).update({"is_primary": False})

    try:
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        raise BadRequest("Duplicate contact")

    current_app.logger.info(
        "EmergencyContact updated userId=%s contactId=%s primary=%s phone=%s",
        g.user.id, contact.id, contact.is_primary, _mask_phone(contact.phone)
    )
    return jsonify(EmergencyContactSchema().dump(contact))


@bp.delete("/<int:cid>")
@require_auth()
def delete_contact(cid: int):
    if safe_mode_on():
        raise Forbidden("Safe mode enabled")

    contact = EmergencyContact.query.get_or_404(cid)
    if contact.user_id != g.user.id:
        raise Forbidden("Not yours")

    db.session.delete(contact)
    db.session.commit()

    current_app.logger.info(
        "EmergencyContact deleted userId=%s contactId=%s phone=%s",
        g.user.id, contact.id, _mask_phone(contact.phone)
    )
    return jsonify({"ok": True})
