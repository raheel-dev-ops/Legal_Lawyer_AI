from flask import current_app
from ..utils.crypto_utils import encrypt_secret, decrypt_secret


CHAT_PROVIDERS = {"openai", "openrouter", "groq", "deepseek", "grok", "anthropic"}
VOICE_PROVIDERS = {"openai", "openrouter", "groq"}


def _normalize(value: str | None, allowed: set[str], default: str) -> str:
    raw = (value or "").strip().lower()
    return raw if raw in allowed else default


def _key_attr(provider: str) -> str:
    return f"{provider}_api_key_enc"


def get_key(user, provider: str) -> str | None:
    enc = getattr(user, _key_attr(provider), None)
    if not enc:
        return None
    return decrypt_secret(enc)


def set_key(user, provider: str, value: str | None) -> None:
    attr = _key_attr(provider)
    if value is None:
        setattr(user, attr, None)
        return
    enc = encrypt_secret(value)
    setattr(user, attr, enc if enc else None)


def chat_provider_for(user, override: str | None = None) -> str:
    default = current_app.config.get("CHAT_PROVIDER", "openai")
    return _normalize(override or getattr(user, "chat_provider", None), CHAT_PROVIDERS, default)


def voice_provider_for(user, override: str | None = None) -> str:
    return _normalize(override or getattr(user, "voice_provider", None), VOICE_PROVIDERS, "openai")


def chat_model_for(user, override: str | None = None) -> str | None:
    model = (override or getattr(user, "chat_model", None) or "").strip()
    return model or None


def voice_model_for(user, override: str | None = None) -> str | None:
    model = (override or getattr(user, "voice_model", None) or "").strip()
    return model or None


def build_api_keys(user) -> dict:
    keys = {}
    for provider in CHAT_PROVIDERS:
        key = get_key(user, provider)
        if key:
            keys[provider] = key
    return keys


def build_voice_keys(user) -> dict:
    keys = {}
    for provider in VOICE_PROVIDERS:
        key = get_key(user, provider)
        if key:
            keys[provider] = key
    return keys


def key_status(user) -> dict:
    status = {}
    for provider in CHAT_PROVIDERS:
        key = get_key(user, provider)
        status[provider] = {
            "configured": bool(key),
            "last4": key[-4:] if key else None,
        }
    return status
