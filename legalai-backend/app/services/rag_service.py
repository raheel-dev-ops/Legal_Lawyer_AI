import time
from flask import current_app

from ..extensions import db
from ..models.rag import KnowledgeChunk, KnowledgePage
from .embedding_service import TextEmbeddingService, ColPaliEmbeddingService
from .qdrant_service import QdrantService
from .reranker_service import RerankerService
from ..utils.text_normalizer import normalize_rag_context


class RAGService:
    _page_retrieval_disabled = False
    @staticmethod
    def hybrid_search(question: str, language: str | None = None) -> dict:
        t0 = time.perf_counter()
        text_top_k = int(current_app.config.get("RAG_TEXT_TOP_K", 12))
        page_top_k = int(current_app.config.get("RAG_PAGE_TOP_K", 6))
        context_text_k = int(current_app.config.get("RAG_CONTEXT_TEXT_K", 5))
        context_image_k = int(current_app.config.get("RAG_CONTEXT_IMAGE_K", 3))
        rerank_candidates = int(current_app.config.get("RERANKER_CANDIDATES", max(text_top_k, context_text_k)))

        text_hits = []
        page_hits = []

        embedding_start = time.perf_counter()
        try:
            text_dim = TextEmbeddingService.embedding_dimension()
            if not text_dim:
                raise RuntimeError("TEXT_EMBEDDING_DIMENSION is not configured.")
            if text_dim:
                QdrantService.ensure_text_collection(text_dim)
            text_vec = TextEmbeddingService.embed(question)
            text_hits = QdrantService.search_text(
                query_vector=text_vec,
                top_k=text_top_k,
                language=language,
            )
        except Exception as e:
            current_app.logger.warning("Text retrieval failed: %s", str(e))

        try:
            if current_app.config.get("ENABLE_PAGE_RETRIEVAL", True) and not RAGService._page_retrieval_disabled:
                page_dim = ColPaliEmbeddingService.embedding_dimension()
                if not page_dim:
                    raise RuntimeError("IMAGE_EMBEDDING_DIMENSION is not configured.")
                if page_dim:
                    QdrantService.ensure_page_collection(page_dim)
                page_vec = ColPaliEmbeddingService.embed_texts(question)
                page_hits = QdrantService.search_pages(
                    query_vector=page_vec,
                    top_k=page_top_k,
                    language=language,
                )
        except Exception as e:
            current_app.logger.warning("Page retrieval failed: %s", str(e))
            if "config.json" in str(e) or "not appear to have a file named" in str(e):
                RAGService._page_retrieval_disabled = True
                current_app.config["ENABLE_PAGE_RETRIEVAL"] = False
                current_app.logger.warning("Page retrieval disabled due to model load failure.")

        embedding_time_ms = int((time.perf_counter() - embedding_start) * 1000)

        text_ids = [h.id for h in text_hits]
        chunk_map = {}
        if text_ids:
            rows = (
                KnowledgeChunk.query
                .filter(KnowledgeChunk.id.in_(text_ids))
                .with_entities(KnowledgeChunk.id, KnowledgeChunk.chunk_text)
                .all()
            )
            chunk_map = {r.id: r.chunk_text for r in rows}

        text_results = []
        for hit in text_hits:
            text = chunk_map.get(hit.id)
            if text:
                text_results.append({
                    "chunk_id": hit.id,
                    "chunk_text": text,
                    "score": float(hit.score),
                })

        reranked = text_results
        if text_results:
            try:
                candidates = text_results[:rerank_candidates]
                ranked = RerankerService.rerank(
                    question,
                    [c["chunk_text"] for c in candidates],
                )
                reranked = [
                    {
                        **candidates[idx],
                        "rerank_score": score,
                    }
                    for idx, score in ranked
                ]
            except Exception as e:
                current_app.logger.warning("Reranker failed: %s", str(e))

        contexts_text = [normalize_rag_context(r["chunk_text"]) for r in reranked[:context_text_k]]
        chunk_ids = [r["chunk_id"] for r in reranked[:context_text_k]]

        page_ids = [h.id for h in page_hits]
        page_map = {}
        if page_ids:
            rows = (
                KnowledgePage.query
                .filter(KnowledgePage.id.in_(page_ids))
                .with_entities(KnowledgePage.id, KnowledgePage.image_path, KnowledgePage.page_number)
                .all()
            )
            page_map = {r.id: r for r in rows}

        page_results = []
        for hit in page_hits:
            row = page_map.get(hit.id)
            if row:
                page_results.append({
                    "page_id": hit.id,
                    "image_path": row.image_path,
                    "page_number": row.page_number,
                    "score": float(hit.score),
                })

        contexts_images = page_results[:context_image_k]
        page_ids_used = [p["page_id"] for p in contexts_images]

        best_text_score = max([r["score"] for r in text_results], default=None)
        best_page_score = max([r["score"] for r in page_results], default=None)

        text_threshold = float(current_app.config.get("RAG_TEXT_SCORE_THRESHOLD", 0.2))
        page_threshold = float(current_app.config.get("RAG_PAGE_SCORE_THRESHOLD", 0.2))

        has_text = best_text_score is not None and best_text_score >= text_threshold
        has_page = best_page_score is not None and best_page_score >= page_threshold
        has_verified_sources = has_text or has_page

        best_score = max(
            [s for s in [best_text_score, best_page_score] if s is not None],
            default=None,
        )
        threshold_used = page_threshold if (best_page_score or 0) >= (best_text_score or 0) else text_threshold

        elapsed_ms = int((time.perf_counter() - t0) * 1000)
        current_app.logger.info(
            "RAG hybrid search complete text_hits=%s page_hits=%s ms=%s",
            len(text_results),
            len(page_results),
            elapsed_ms,
        )

        return {
            "text_results": text_results,
            "page_results": page_results,
            "contexts_text": contexts_text if has_verified_sources else [],
            "contexts_images": contexts_images if has_verified_sources else [],
            "chunk_ids": chunk_ids if has_verified_sources else [],
            "page_ids": page_ids_used if has_verified_sources else [],
            "best_score": best_score,
            "threshold_used": threshold_used,
            "has_verified_sources": has_verified_sources,
            "contexts_found": len(text_results) + len(page_results),
            "contexts_used": (len(contexts_text) + len(contexts_images)) if has_verified_sources else 0,
            "embedding_time_ms": embedding_time_ms,
        }
