import os
from typing import List
from sentence_transformers import SentenceTransformer

_model = None

def get_model_name() -> str:
    return os.getenv("MODEL_NAME", "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2")

def get_model():
    global _model
    if _model is None:
        _model = SentenceTransformer(get_model_name())
    return _model

def embed_texts(texts: List[str]) -> List[List[float]]:
    model = get_model()
    return model.encode(texts, normalize_embeddings=True).tolist()

def embed_text(text: str) -> List[float]:
    return embed_texts([text])[0]
