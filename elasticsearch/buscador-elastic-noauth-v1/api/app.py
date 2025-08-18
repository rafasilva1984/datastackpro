import os
from datetime import datetime, timezone
from fastapi import FastAPI
from pydantic import BaseModel
from dotenv import load_dotenv

from utils.loaders import load_local_docs
from utils.es_utils import ensure_index, bulk_index, hybrid_search
from utils.embedder import embed_texts, embed_text

load_dotenv()
LOCAL_DIR = os.getenv("LOCAL_DOCS_DIR", "/app/data/docs")

app = FastAPI(title="Buscador Elastic (no-auth)", version="1.2.0")

class IngestResponse(BaseModel):
    local_docs: int
    total_chunks: int
    used_embeddings: bool

class SearchRequest(BaseModel):
    query: str
    k: int = 5
    categoria: str | None = None
    tags: list[str] | None = None

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/ingest", response_model=IngestResponse)
def ingest():
    ensure_index()
    items = load_local_docs(LOCAL_DIR)
    if not items:
        return IngestResponse(local_docs=0, total_chunks=0, used_embeddings=False)

    # metadados simples automáticos + timestamp
    for it in items:
        text_lc = (it["title"] + " " + it["text"]).lower()
        if "vpn" in text_lc or "mfa" in text_lc:
            it["categoria"] = "Infra"; it["tags"] = ["vpn","mfa"]
        elif "home office" in text_lc or "remoto" in text_lc:
            it["categoria"] = "RH"; it["tags"] = ["home-office","remoto","beneficios"]
        elif "viagem" in text_lc or "hospedagem" in text_lc:
            it["categoria"] = "RH"; it["tags"] = ["viagens","reembolso"]
        elif "sla" in text_lc:
            it["categoria"] = "Suporte"; it["tags"] = ["sla"]
        elif "lgpd" in text_lc:
            it["categoria"] = "Compliance"; it["tags"] = ["lgpd"]
        elif "cab" in text_lc:
            it["categoria"] = "Mudanças"; it["tags"] = ["cab","change"]
        it["ingested_at"] = datetime.now(timezone.utc).isoformat()

    embeds = embed_texts([it["text"] for it in items])  # pode ser None (fallback)
    bulk_index(items, embeddings=embeds)
    return IngestResponse(local_docs=len(items), total_chunks=len(items), used_embeddings=embeds is not None)

@app.post("/search")
def search(req: SearchRequest):
    qvec = embed_text(req.query)  # pode ser None
    results = hybrid_search(req.query, qvec, k=req.k,
                            categoria=req.categoria, tags=req.tags)
    return {"results": results}
