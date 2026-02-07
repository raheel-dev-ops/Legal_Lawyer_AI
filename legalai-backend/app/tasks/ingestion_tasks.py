import time
from .celery_app import celery
from ..extensions import db
from ..models.rag import KnowledgeSource, KnowledgeChunk, KnowledgePage
from ..services.embedding_service import TextEmbeddingService, ColPaliEmbeddingService
from ..services.qdrant_service import QdrantService
from ..utils.text_extract import extract_text_from_source, chunk_text, ocr_images_to_text
from ..utils.page_render import render_source_pages
from flask import current_app

_TASK_APP = None
MAX_AUTO_INGEST_RETRIES = 5



def _get_task_app():
    """
    Return a Flask app instance usable inside Celery worker tasks.

    - If a Flask app context is already active, reuse it.
    - Otherwise, create the app once via create_app() and cache it.
    """
    global _TASK_APP
    if _TASK_APP is not None:
        return _TASK_APP

    try:
        _TASK_APP = current_app._get_current_object()
        return _TASK_APP
    except Exception:
        from .. import create_app

        _TASK_APP = create_app()
        return _TASK_APP
def _retry_sleep(attempt: int):
    time.sleep(min(2 ** attempt, 20))


@celery.task
def ingest_source(source_id: int):
    app = _get_task_app()
    with app.app_context():
        src = KnowledgeSource.query.get(source_id)
        if not src:
            return

        try:
            src.retry_count = (src.retry_count or 0) + 1
            src.status = "processing"
            src.error_message = None
            db.session.commit()

            KnowledgeChunk.query.filter_by(source_id=src.id).delete()
            KnowledgePage.query.filter_by(source_id=src.id).delete()
            db.session.commit()

            try:
                QdrantService.delete_source_points(src.id)
            except Exception as e:
                current_app.logger.warning("Qdrant delete failed for source=%s err=%s", src.id, str(e))

            text = extract_text_from_source(src)
            chunks = chunk_text(text)
            chunks = [c for c in chunks if c and len(c.strip()) >= 5]

            text_batch_size = int(current_app.config.get("TEXT_EMBEDDING_BATCH_SIZE", 32))
            text_model_name = current_app.config.get("TEXT_EMBEDDING_MODEL", "BAAI/bge-m3")
            text_dim = TextEmbeddingService.embedding_dimension()

            if chunks and not text_dim:
                raise RuntimeError("TEXT_EMBEDDING_DIMENSION is not configured and model dimension could not be inferred.")

            if chunks and text_dim:
                QdrantService.ensure_text_collection(text_dim)

            for i in range(0, len(chunks), text_batch_size):
                batch = chunks[i:i + text_batch_size]
                rows = [
                    KnowledgeChunk(
                        source_id=src.id,
                        chunk_text=ch,
                        embedding_model=text_model_name,
                        embedding_dimension=text_dim,
                    )
                    for ch in batch
                ]
                db.session.add_all(rows)
                db.session.flush()

                for attempt in range(3):
                    try:
                        embs = TextEmbeddingService.embed(batch)
                        break
                    except Exception as e:
                        if attempt == 2:
                            raise e
                        _retry_sleep(attempt + 1)

                payloads = [
                    {
                        "source_id": src.id,
                        "chunk_id": row.id,
                        "language": src.language,
                        "title": src.title,
                        "source_type": src.source_type,
                    }
                    for row in rows
                ]
                QdrantService.upsert_text_points(
                    ids=[row.id for row in rows],
                    vectors=embs,
                    payloads=payloads,
                )

            pages = render_source_pages(src.id, src.source_type, src.file_path or "")
            page_dim = None
            image_embedding_ready = True
            if pages:
                try:
                    page_dim = ColPaliEmbeddingService.embedding_dimension()
                    if not page_dim:
                        raise RuntimeError("IMAGE_EMBEDDING_DIMENSION is not configured.")
                except Exception as e:
                    current_app.logger.warning("ColPali init failed for source=%s err=%s", src.id, str(e))
                    image_embedding_ready = False

            if pages and page_dim:
                QdrantService.ensure_page_collection(page_dim)

            page_batch = int(current_app.config.get("IMAGE_EMBEDDING_BATCH_SIZE", 8))
            if pages:
                for i in range(0, len(pages), page_batch):
                    batch = pages[i:i + page_batch]
                    rows = [
                        KnowledgePage(
                            source_id=src.id,
                            page_number=p["page_number"],
                            image_path=p["path"],
                            width=p.get("width"),
                            height=p.get("height"),
                        )
                        for p in batch
                    ]
                    db.session.add_all(rows)
                    db.session.flush()

                    page_vectors = []
                    if image_embedding_ready and page_dim:
                        try:
                            page_vectors = ColPaliEmbeddingService.embed_images([p["path"] for p in batch])
                        except Exception as e:
                            current_app.logger.warning("ColPali embed failed for source=%s err=%s", src.id, str(e))
                            page_vectors = []

                    payloads = [
                        {
                            "source_id": src.id,
                            "page_id": row.id,
                            "page_number": row.page_number,
                            "language": src.language,
                            "title": src.title,
                            "source_type": src.source_type,
                        }
                        for row in rows
                    ]
                    if page_vectors:
                        QdrantService.upsert_page_points(
                            ids=[row.id for row in rows],
                            vectors=page_vectors,
                            payloads=payloads,
                        )

            if not chunks and pages:
                ocr_text = ocr_images_to_text([p["path"] for p in pages], force=not image_embedding_ready)
                if ocr_text:
                    chunks = chunk_text(ocr_text)

            db.session.commit()

            if not chunks and not pages:
                src.status = "invalid"
                src.error_message = "No text chunks or pages produced from source."
                db.session.commit()
                return

            src.status = "done"
            src.error_message = None
            src.embedding_model = text_model_name
            src.embedding_dimension = text_dim
            db.session.commit()

        except Exception as e:
            db.session.rollback()
            src.status = "failed"
            src.error_message = str(e)
            db.session.commit()

            if (src.retry_count or 0) < MAX_AUTO_INGEST_RETRIES:
                src.status = "queued"
                db.session.commit()
                delay = min(2 ** (src.retry_count or 1), 60)
                ingest_source.apply_async((src.id,), countdown=delay)

@celery.task
def retry_stale_knowledge_sources():
    """
    Periodic watchdog task that retries knowledge sources that are still
    not ingested successfully.

    Rules:
      - Only status in ("queued", "failed") are auto-retired.
      - status == "invalid" is never auto-retired (permanent input problem).
      - Automatic retries stop when retry_count >= MAX_AUTO_INGEST_RETRIES.
      - Manual admin retries are still allowed beyond MAX_AUTO_INGEST_RETRIES.
    """
    stale = KnowledgeSource.query.filter(
        KnowledgeSource.status.in_(("queued", "failed")),
        KnowledgeSource.retry_count < MAX_AUTO_INGEST_RETRIES,
    ).all()

    for src in stale:
        ingest_source.delay(src.id)


@celery.on_after_configure.connect
def setup_periodic_ingestion_retry(sender, **kwargs):
    """
    Register periodic execution for retrying stale knowledge sources.

    This uses a 24-hour interval based on the system time of the environment
    where Celery is running, avoiding time-zone assumptions.
    """
    sender.add_periodic_task(
        24 * 60 * 60,
        retry_stale_knowledge_sources.s(),
        name="retry_stale_knowledge_sources_every_24h",
    )
