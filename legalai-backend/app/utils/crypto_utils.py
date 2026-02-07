import os
from cryptography.fernet import Fernet, InvalidToken


_fernet = None


def _get_fernet() -> Fernet:
    global _fernet
    if _fernet is not None:
        return _fernet
    key = (os.getenv("USER_API_KEYS_ENC_KEY") or "").strip()
    if not key:
        raise RuntimeError("Server encryption key is not configured.")
    try:
        _fernet = Fernet(key)
    except Exception as exc:
        raise RuntimeError("Server encryption key is invalid.") from exc
    return _fernet


def encrypt_secret(value: str) -> str:
    if value is None:
        return ""
    raw = value.strip()
    if not raw:
        return ""
    f = _get_fernet()
    token = f.encrypt(raw.encode("utf-8"))
    return token.decode("utf-8")


def decrypt_secret(value: str | None) -> str | None:
    if not value:
        return None
    f = _get_fernet()
    try:
        plain = f.decrypt(value.encode("utf-8"))
        return plain.decode("utf-8").strip() or None
    except InvalidToken:
        return None
