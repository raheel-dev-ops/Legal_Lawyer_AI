import hashlib
import json
from typing import Any

from flask import current_app, jsonify, request


def _stable_json(payload: Any) -> str:
    return json.dumps(
        payload,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    )


def build_etag(payload: Any) -> str:
    digest = hashlib.sha256(_stable_json(payload).encode("utf-8")).hexdigest()
    return f"\"{digest}\""


def etag_response(payload: Any):
    etag = build_etag(payload)
    inm = request.headers.get("If-None-Match")
    if inm == etag:
        resp = current_app.response_class(status=304)
    else:
        resp = jsonify(payload)
    resp.headers["ETag"] = etag
    resp.headers["Cache-Control"] = "no-cache"
    return resp
