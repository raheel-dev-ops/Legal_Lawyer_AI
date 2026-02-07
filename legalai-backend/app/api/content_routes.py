from flask import Blueprint, jsonify, current_app
from sqlalchemy import func
from ..models.content import Right, Template, Pathway
from ..extensions import db
from ..utils.http_cache import etag_response

bp = Blueprint("content", __name__)

@bp.get("/manifest")
def manifest():
    """
    Manifest format expected by ContentSyncService:
    {
      "version": <int>,
      "files": {
        "rights": {"url": "..."},
        "templates": {"url": "..."}
      }
    }
    """
    config_version = current_app.config.get("CONTENT_VERSION", 1)
    try:
        config_version = int(config_version)
    except (TypeError, ValueError):
        config_version = 1

    latest_right, right_count = db.session.query(
        func.max(Right.updated_at), func.count(Right.id)
    ).one()
    latest_template, template_count = db.session.query(
        func.max(Template.updated_at), func.count(Template.id)
    ).one()
    latest_pathway, pathway_count = db.session.query(
        func.max(Pathway.updated_at), func.count(Pathway.id)
    ).one()

    latest = max(
        [dt for dt in (latest_right, latest_template, latest_pathway) if dt is not None],
        default=None,
    )
    total_count = int(right_count or 0) + int(template_count or 0) + int(pathway_count or 0)

    computed_version = total_count
    if latest is not None:
        computed_version = int(latest.timestamp()) * 1000 + total_count

    version = max(config_version, computed_version)
    payload = {
        "version": int(version),
        "files": {
            "rights": {"url": "/api/v1/content/rights.json"},
            "templates": {"url": "/api/v1/content/templates.json"},
            "pathways": {"url": "/api/v1/content/pathways.json"}
        }
    }
    return etag_response(payload)

@bp.get("/rights.json")
def rights_json():
    rights = Right.query.order_by(Right.updated_at.desc()).all()
    return jsonify([{
        "id": r.id,
        "topic": r.topic,
        "body": r.body,
        "category": r.category,
        "language": r.language,
        "tags": r.tags
    } for r in rights])

@bp.get("/templates.json")
def templates_json():
    templates = Template.query.order_by(Template.updated_at.desc()).all()
    return jsonify([{
        "id": t.id,
        "title": t.title,
        "category": t.category,
        "description": t.description,
        "body": t.body,
        "language": t.language,
        "tags": t.tags
    } for t in templates])

@bp.get("/pathways.json")
def pathways_json():
    pathways = Pathway.query.order_by(Pathway.id.desc()).all()
    return jsonify([{
        "id": p.id,
        "title": p.title,
        "summary": p.summary,
        "steps": p.steps,
        "category": p.category,
        "language": p.language,
        "tags": p.tags
    } for p in pathways])
