import json
from typing import Any

import requests
from flask import current_app

from ..models.reminders import DeviceToken

try:
    from google.auth.transport.requests import Request
    from google.oauth2 import service_account
except Exception:  # pragma: no cover - optional dependency
    Request = None
    service_account = None


class PushService:
    _credentials = None
    _project_id = None

    @staticmethod
    def _load_service_account_info() -> dict[str, Any] | None:
        raw = current_app.config.get("FCM_SERVICE_ACCOUNT_JSON")
        path = current_app.config.get("FCM_SERVICE_ACCOUNT_FILE")
        if raw:
            return json.loads(raw)
        if path:
            with open(path, "r", encoding="utf-8") as handle:
                return json.load(handle)
        return None

    @staticmethod
    def _get_credentials():
        if service_account is None or Request is None:
            current_app.logger.warning("FCM HTTP v1 requires google-auth")
            return None

        if PushService._credentials is not None:
            return PushService._credentials

        info = PushService._load_service_account_info()
        if not info:
            return None

        PushService._credentials = service_account.Credentials.from_service_account_info(
            info, scopes=["https://www.googleapis.com/auth/firebase.messaging"]
        )
        if not PushService._project_id:
            PushService._project_id = current_app.config.get("FCM_PROJECT_ID") or info.get(
                "project_id"
            )
        return PushService._credentials

    @staticmethod
    def _get_access_token() -> str | None:
        credentials = PushService._get_credentials()
        if not credentials:
            return None
        if not credentials.valid or credentials.expired:
            credentials.refresh(Request())
        return credentials.token

    @staticmethod
    def _get_project_id() -> str | None:
        if PushService._project_id:
            return PushService._project_id
        project_id = current_app.config.get("FCM_PROJECT_ID")
        if project_id:
            PushService._project_id = project_id
            return project_id
        info = PushService._load_service_account_info()
        if info and info.get("project_id"):
            PushService._project_id = info["project_id"]
            return PushService._project_id
        return None

    @staticmethod
    def _stringify_data(data: dict[str, Any] | None) -> dict[str, str] | None:
        if not data:
            return None
        payload: dict[str, str] = {}
        for key, value in data.items():
            if isinstance(value, (dict, list)):
                payload[str(key)] = json.dumps(value)
            else:
                payload[str(key)] = str(value)
        return payload

    @staticmethod
    def _message_payload(title: str, body: str, data: dict[str, Any] | None = None) -> dict[str, Any]:
        message: dict[str, Any] = {
            "notification": {"title": title, "body": body},
            "android": {"priority": "high"},
            "apns": {
                "headers": {"apns-priority": "10"},
                "payload": {"aps": {"sound": "default"}},
            },
        }
        data_payload = PushService._stringify_data(data)
        if data_payload:
            message["data"] = data_payload
        return message

    @staticmethod
    def _post_message(message: dict[str, Any]) -> None:
        access_token = PushService._get_access_token()
        project_id = PushService._get_project_id()
        if not access_token or not project_id:
            return

        url = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json; UTF-8",
        }
        try:
            requests.post(url, headers=headers, json={"message": message}, timeout=20)
        except Exception:
            current_app.logger.exception("FCM HTTP v1 send failed")

    @staticmethod
    def send_fcm(tokens: list[str], title: str, body: str, data=None):
        if not tokens:
            return
        base = PushService._message_payload(title, body, data=data)
        for token in tokens:
            message = dict(base)
            message["token"] = token
            PushService._post_message(message)

    @staticmethod
    def send_fcm_topic(topic: str, title: str, body: str, data=None):
        if not topic:
            return
        message = PushService._message_payload(title, body, data=data)
        message["topic"] = topic
        PushService._post_message(message)

    @staticmethod
    def send_to_user(user_id: int, title: str, body: str, data=None):
        tokens = [t.token for t in DeviceToken.query.filter_by(user_id=user_id).all()]
        PushService.send_fcm(tokens, title, body, data=data)
