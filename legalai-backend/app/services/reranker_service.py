from typing import Iterable

from flask import current_app

try:
    import torch
except Exception:  # pragma: no cover
    torch = None


class RerankerService:
    _model = None
    _tokenizer = None
    _model_name = None
    _device = None

    @staticmethod
    def _load_model():
        if RerankerService._model is not None:
            return RerankerService._model, RerankerService._tokenizer

        if torch is None:  # pragma: no cover
            raise RuntimeError("torch is required for reranker.")

        try:
            from transformers import AutoTokenizer, AutoModelForSequenceClassification
        except Exception as e:  # pragma: no cover
            raise RuntimeError("transformers is required for reranker.") from e

        model_name = current_app.config.get("RERANKER_MODEL", "BAAI/bge-reranker-v2-m3")
        device = current_app.config.get("RERANKER_DEVICE", "cpu")

        tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
        model = AutoModelForSequenceClassification.from_pretrained(model_name, trust_remote_code=True)
        model.to(device)
        model.eval()

        RerankerService._model = model
        RerankerService._tokenizer = tokenizer
        RerankerService._model_name = model_name
        RerankerService._device = device
        return model, tokenizer

    @staticmethod
    def rerank(query: str, passages: Iterable[str]):
        passages = list(passages or [])
        if not passages:
            return []

        model, tokenizer = RerankerService._load_model()

        pairs = [(query, p) for p in passages]
        encoded = tokenizer(
            pairs,
            padding=True,
            truncation=True,
            return_tensors="pt",
            max_length=int(current_app.config.get("RERANKER_MAX_LENGTH", 512)),
        )
        encoded = {k: v.to(RerankerService._device) for k, v in encoded.items()}

        with torch.no_grad():
            outputs = model(**encoded)
            scores = outputs.logits.squeeze(-1).detach().cpu().tolist()
            if isinstance(scores, float):
                scores = [scores]

        ranked = list(zip(range(len(passages)), scores))
        ranked.sort(key=lambda x: x[1], reverse=True)
        return ranked
