import os
from fastapi import FastAPI
from pydantic import BaseModel
from dotenv import load_dotenv

from utils.loaders import load_local_docs
from utils.es_utils import ensure_index, bulk_index, knn_search, text_search
from utils.embedder import embed_texts, embed_text

load_dotenv()
LOCAL_DIR = os.getenv("LOCAL_DOCS_DIR", "/app/data/docs")

app = FastAPI(title="Buscador Elastic (no-auth)", version="1.1.0")

class IngestResponse(BaseModel):
    local_docs: int
    total_chunks: int
    used_embeddings: bool

class SearchRequest(BaseModel):
    query: str
    k: int = 5

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/ingest", response_model=IngestResponse)
def ingest():
    ensure_index()
    items = load_local_docs(LOCAL_DIR)
    if not items:
        return IngestResponse(local_docs=0, total_chunks=0, used_embeddings=False)

    embeds = embed_texts([it["text"] for it in items])  # pode retornar None
    bulk_index(items, embeddings=embeds)
    return IngestResponse(local_docs=len(items), total_chunks=len(items), used_embeddings=embeds is not None)

@app.post("/search")
def search(req: SearchRequest):
    vec = embed_text(req.query)  # pode ser None
    if vec is None:
        results = text_search(req.query, k=req.k)
    else:
        results = knn_search(vec, k=req.k)
    return {"results": results}
