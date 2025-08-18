import os
from typing import List, Optional

_model = None
_model_failed = False

def get_model_name() -> str:
    return os.getenv("MODEL_NAME", "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2")

def _load_model():
    global _model, _model_failed
    if _model is not None or _model_failed:
        return
    try:
        from sentence_transformers import SentenceTransformer
        _model = SentenceTransformer(get_model_name())
    except Exception as e:
        # Ambiente sem internet/SSL corporativo etc.
        _model = None
        _model_failed = True

def embed_texts(texts: List[str]) -> Optional[List[List[float]]]:
    _load_model()
    if _model is None:
        return None
    return _model.encode(texts, normalize_embeddings=True).tolist()

def embed_text(text: str) -> Optional[List[float]]:
    res = embed_texts([text])
    return None if res is None else res[0]
