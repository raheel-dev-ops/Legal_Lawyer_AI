import os
from typing import Iterable, Optional

from flask import current_app

try:
    from qdrant_client import QdrantClient
    from qdrant_client.http import models as qdrant_models
except Exception:  # pragma: no cover - optional dependency
    QdrantClient = None
    qdrant_models = None


class QdrantService:
    _client = None

    @staticmethod
    def _client_instance() -> "QdrantClient":
        if QdrantClient is None:
            raise RuntimeError("qdrant-client is not installed. Add it to requirements.txt.")

        if QdrantService._client is not None:
            return QdrantService._client

        url = current_app.config.get("QDRANT_URL")
        api_key = current_app.config.get("QDRANT_API_KEY")
        timeout = current_app.config.get("QDRANT_TIMEOUT", 30)

        if url:
            QdrantService._client = QdrantClient(url=url, api_key=api_key, timeout=timeout)
        else:
            host = current_app.config.get("QDRANT_HOST", "localhost")
            port = int(current_app.config.get("QDRANT_PORT", 6333))
            QdrantService._client = QdrantClient(host=host, port=port, api_key=api_key, timeout=timeout)

        return QdrantService._client

    @staticmethod
    def _ensure_collection(name: str, vector_size: int):
        client = QdrantService._client_instance()
        try:
            client.get_collection(name)
            return
        except Exception:
            pass

        client.create_collection(
            collection_name=name,
            vectors_config=qdrant_models.VectorParams(
                size=int(vector_size),
                distance=qdrant_models.Distance.COSINE,
            ),
        )

    @staticmethod
    def ensure_text_collection(vector_size: int):
        QdrantService._ensure_collection(
            current_app.config["QDRANT_TEXT_COLLECTION"],
            vector_size,
        )

    @staticmethod
    def ensure_page_collection(vector_size: int):
        QdrantService._ensure_collection(
            current_app.config["QDRANT_PAGE_COLLECTION"],
            vector_size,
        )

    @staticmethod
    def upsert_text_points(*, ids: Iterable[int], vectors: Iterable[list[float]], payloads: Iterable[dict]):
        client = QdrantService._client_instance()
        points = [
            qdrant_models.PointStruct(id=pid, vector=vec, payload=payload)
            for pid, vec, payload in zip(ids, vectors, payloads)
        ]
        if not points:
            return
        client.upsert(collection_name=current_app.config["QDRANT_TEXT_COLLECTION"], points=points)

    @staticmethod
    def upsert_page_points(*, ids: Iterable[int], vectors: Iterable[list[float]], payloads: Iterable[dict]):
        client = QdrantService._client_instance()
        points = [
            qdrant_models.PointStruct(id=pid, vector=vec, payload=payload)
            for pid, vec, payload in zip(ids, vectors, payloads)
        ]
        if not points:
            return
        client.upsert(collection_name=current_app.config["QDRANT_PAGE_COLLECTION"], points=points)

    @staticmethod
    def search_text(*, query_vector: list[float], top_k: int, language: Optional[str] = None):
        client = QdrantService._client_instance()
        flt = QdrantService._language_filter(language)
        return client.search(
            collection_name=current_app.config["QDRANT_TEXT_COLLECTION"],
            query_vector=query_vector,
            limit=int(top_k),
            with_payload=True,
            query_filter=flt,
        )

    @staticmethod
    def search_pages(*, query_vector: list[float], top_k: int, language: Optional[str] = None):
        client = QdrantService._client_instance()
        flt = QdrantService._language_filter(language)
        return client.search(
            collection_name=current_app.config["QDRANT_PAGE_COLLECTION"],
            query_vector=query_vector,
            limit=int(top_k),
            with_payload=True,
            query_filter=flt,
        )

    @staticmethod
    def delete_source_points(source_id: int):
        client = QdrantService._client_instance()
        flt = qdrant_models.Filter(
            must=[
                qdrant_models.FieldCondition(
                    key="source_id",
                    match=qdrant_models.MatchValue(value=source_id),
                )
            ]
        )
        selector = qdrant_models.FilterSelector(filter=flt)

        client.delete(collection_name=current_app.config["QDRANT_TEXT_COLLECTION"], points_selector=selector)
        client.delete(collection_name=current_app.config["QDRANT_PAGE_COLLECTION"], points_selector=selector)

    @staticmethod
    def _language_filter(language: Optional[str]):
        if not language:
            return None
        return qdrant_models.Filter(
            must=[
                qdrant_models.FieldCondition(
                    key="language",
                    match=qdrant_models.MatchValue(value=language),
                )
            ]
        )
