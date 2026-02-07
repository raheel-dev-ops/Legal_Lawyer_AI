import time
from typing import Iterable

from flask import current_app

try:
    import torch
except Exception:  # pragma: no cover
    torch = None


class TextEmbeddingService:
    _model = None
    _model_name = None
    _device = None

    @staticmethod
    def _load_model():
        provider = current_app.config.get("TEXT_EMBEDDING_PROVIDER", "local")
        if provider not in {"local", "bge", "bge-m3"}:
            from .llm_service import LLMService
            return LLMService, provider

        if TextEmbeddingService._model is not None:
            return TextEmbeddingService._model, provider

        try:
            from sentence_transformers import SentenceTransformer
        except Exception as e:  # pragma: no cover
            raise RuntimeError("sentence-transformers is required for local embeddings.") from e

        model_name = current_app.config.get("TEXT_EMBEDDING_MODEL", "BAAI/bge-m3")
        device = current_app.config.get("TEXT_EMBEDDING_DEVICE", "cpu")
        TextEmbeddingService._model = SentenceTransformer(model_name, device=device)
        TextEmbeddingService._model_name = model_name
        TextEmbeddingService._device = device
        return TextEmbeddingService._model, provider

    @staticmethod
    def embedding_dimension() -> int:
        model, provider = TextEmbeddingService._load_model()
        if provider not in {"local", "bge", "bge-m3"}:
            return int(current_app.config.get("TEXT_EMBEDDING_DIMENSION", 0) or 0)
        return int(model.get_sentence_embedding_dimension())

    @staticmethod
    def embed(text_or_texts: Iterable[str] | str):
        model, provider = TextEmbeddingService._load_model()
        is_batch = isinstance(text_or_texts, list)
        inputs = text_or_texts if is_batch else [text_or_texts]

        if provider not in {"local", "bge", "bge-m3"}:
            llm_service = model
            return llm_service.embed(inputs) if is_batch else llm_service.embed(inputs)[0]

        t0 = time.perf_counter()
        batch_size = int(current_app.config.get("TEXT_EMBEDDING_BATCH_SIZE", 32))
        embeddings = model.encode(
            inputs,
            normalize_embeddings=True,
            convert_to_numpy=True,
            batch_size=batch_size,
            show_progress_bar=False,
        )
        elapsed_ms = int((time.perf_counter() - t0) * 1000)
        current_app.logger.info(
            "Text embeddings generated model=%s items=%s ms=%s",
            TextEmbeddingService._model_name,
            len(inputs),
            elapsed_ms,
        )
        return embeddings.tolist() if is_batch else embeddings[0].tolist()


class ColPaliEmbeddingService:
    _model = None
    _processor = None
    _model_name = None
    _device = None

    @staticmethod
    def _load_model():
        if ColPaliEmbeddingService._model is not None:
            return ColPaliEmbeddingService._model, ColPaliEmbeddingService._processor

        if torch is None:  # pragma: no cover
            raise RuntimeError("torch is required for ColPali embeddings.")

        try:
            from transformers import AutoProcessor, AutoModel
        except Exception as e:  # pragma: no cover
            raise RuntimeError("transformers is required for ColPali embeddings.") from e

        model_name = current_app.config.get("IMAGE_EMBEDDING_MODEL", "vidore/colpali")
        device = current_app.config.get("IMAGE_EMBEDDING_DEVICE", "cpu")

        model = AutoModel.from_pretrained(model_name, trust_remote_code=True)
        processor = AutoProcessor.from_pretrained(model_name, trust_remote_code=True)
        model.to(device)
        model.eval()

        ColPaliEmbeddingService._model = model
        ColPaliEmbeddingService._processor = processor
        ColPaliEmbeddingService._model_name = model_name
        ColPaliEmbeddingService._device = device
        return model, processor

    @staticmethod
    def embedding_dimension() -> int:
        model, _ = ColPaliEmbeddingService._load_model()
        if hasattr(model, "config") and hasattr(model.config, "hidden_size"):
            return int(model.config.hidden_size)
        return int(current_app.config.get("IMAGE_EMBEDDING_DIMENSION", 0) or 0)

    @staticmethod
    def embed_texts(texts: Iterable[str] | str):
        model, processor = ColPaliEmbeddingService._load_model()
        is_batch = isinstance(texts, list)
        inputs = texts if is_batch else [texts]

        if torch is None:  # pragma: no cover
            raise RuntimeError("torch is required for ColPali embeddings.")

        encoded = processor(text=inputs, padding=True, truncation=True, return_tensors="pt")
        encoded = {k: v.to(ColPaliEmbeddingService._device) for k, v in encoded.items()}

        with torch.no_grad():
            if hasattr(model, "get_text_features"):
                feats = model.get_text_features(**encoded)
            else:
                outputs = model(**encoded)
                feats = _pool_features(outputs)

        feats = torch.nn.functional.normalize(feats, p=2, dim=-1)
        feats = feats.detach().cpu().tolist()
        return feats if is_batch else feats[0]

    @staticmethod
    def embed_images(images: Iterable):
        model, processor = ColPaliEmbeddingService._load_model()
        if torch is None:  # pragma: no cover
            raise RuntimeError("torch is required for ColPali embeddings.")

        from PIL import Image

        opened = []
        created = []

        def _load_image(item):
            if isinstance(item, Image.Image):
                converted = item.convert("RGB")
                created.append(converted)
                return converted
            img = Image.open(item)
            opened.append(img)
            converted = img.convert("RGB")
            created.append(converted)
            return converted

        try:
            imgs = [_load_image(i) for i in images]
            encoded = processor(images=imgs, return_tensors="pt")
            encoded = {k: v.to(ColPaliEmbeddingService._device) for k, v in encoded.items()}

            with torch.no_grad():
                if hasattr(model, "get_image_features"):
                    feats = model.get_image_features(**encoded)
                else:
                    outputs = model(**encoded)
                    feats = _pool_features(outputs)

            feats = torch.nn.functional.normalize(feats, p=2, dim=-1)
            return feats.detach().cpu().tolist()
        finally:
            for img in created:
                try:
                    img.close()
                except Exception:
                    pass
            for img in opened:
                try:
                    img.close()
                except Exception:
                    pass


def _pool_features(outputs):
    if hasattr(outputs, "pooler_output") and outputs.pooler_output is not None:
        return outputs.pooler_output
    if hasattr(outputs, "last_hidden_state"):
        return outputs.last_hidden_state.mean(dim=1)
    if isinstance(outputs, (list, tuple)) and outputs:
        return outputs[0].mean(dim=1)
    raise RuntimeError("Unable to pool embeddings from ColPali outputs.")
