import os
from datetime import datetime, timezone
from fastapi import FastAPI
from pydantic import BaseModel
from dotenv import load_dotenv

from utils.loaders import load_local_docs
from utils.es_utils import ensure_index, bulk_index, hybrid_search
from utils.embedder import embed_texts, embed_text

# ▼ extra: Confluence + HTML → texto
from atlassian import Confluence
from bs4 import BeautifulSoup

load_dotenv()
LOCAL_DIR = os.getenv("LOCAL_DOCS_DIR", "/app/data/docs")

# Confluence envs (opcionais; só usados se chamar /ingest_confluence)
CONF_URL   = os.getenv("CONFLUENCE_URL")
CONF_USER  = os.getenv("CONFLUENCE_USER")
CONF_TOKEN = os.getenv("CONFLUENCE_TOKEN")
CONF_SPACE = os.getenv("CONFLUENCE_SPACE")

app = FastAPI(title="Buscador Elastic (no-auth)", version="1.3.0")

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

def _auto_metadata(items):
    """Atribui categoria/tags + timestamp automáticamente."""
    for it in items:
        text_lc = (it.get("title","") + " " + it.get("text","")).lower()
        if "vpn" in text_lc or "mfa" in text_lc:
            it["categoria"] = "Infra"; it["tags"] = ["vpn","mfa"]
        elif "home office" in text_lc or "remoto" in text_lc:
            it["categoria"] = "RH"; it["tags"] = ["home-office","remoto","beneficios"]
        elif "viagem" in text_lc or "hospedagem" in text_lc or "reembolso" in text_lc:
            it["categoria"] = "RH"; it["tags"] = ["viagens","reembolso"]
        elif "sla" in text_lc or "incidente p1" in text_lc:
            it["categoria"] = "Suporte"; it["tags"] = ["sla"]
        elif "lgpd" in text_lc or "dados pessoais" in text_lc:
            it["categoria"] = "Compliance"; it["tags"] = ["lgpd"]
        elif "cab" in text_lc or "change" in text_lc:
            it["categoria"] = "Mudanças"; it["tags"] = ["cab","change"]
        it["ingested_at"] = datetime.now(timezone.utc).isoformat()

def _ingest_documents(items):
    """Fluxo padrão de ingestão: embeddings (se disponíveis) + bulk."""
    ensure_index()
    if not items:
        return IngestResponse(local_docs=0, total_chunks=0, used_embeddings=False)
    _auto_metadata(items)
    embeds = embed_texts([it["text"] for it in items])  # pode ser None (fallback p/ full-text)
    bulk_index(items, embeddings=embeds)
    return IngestResponse(local_docs=len(items), total_chunks=len(items), used_embeddings=embeds is not None)

@app.post("/ingest", response_model=IngestResponse)
def ingest_local():
    items = load_local_docs(LOCAL_DIR)
    return _ingest_documents(items)

def _html_to_text(html: str) -> str:
    """Converte HTML Confluence (storage) para texto legível."""
    soup = BeautifulSoup(html or "", "html.parser")
    # remove scripts/styles
    for t in soup(["script","style"]):
        t.extract()
    text = soup.get_text("\n")
    # limpa múltiplas quebras
    lines = [ln.strip() for ln in text.splitlines()]
    text = "\n".join([ln for ln in lines if ln])
    return text

@app.post("/ingest_confluence", response_model=IngestResponse)
def ingest_confluence():
    if not all([CONF_URL, CONF_USER, CONF_TOKEN, CONF_SPACE]):
        # Retorna 200 com info amigável (mantém PoC suave)
        return IngestResponse(local_docs=0, total_chunks=0, used_embeddings=False)

    conf = Confluence(url=CONF_URL, username=CONF_USER, password=CONF_TOKEN)
    # Pegue mais/menos páginas ajustando 'limit'
    pages = conf.get_all_pages_from_space(CONF_SPACE, start=0, limit=50, expand="body.storage,version")

    items = []
    for pg in pages:
        title = pg.get("title","(sem título)")
        html  = (((pg.get("body") or {}).get("storage") or {}).get("value")) or ""
        text  = _html_to_text(html)
        path  = f"{CONF_SPACE}/{pg.get('id')}"
        items.append({
            "title": title,
            "text": text,
            "source": "confluence",
            "path": path
        })

    return _ingest_documents(items)

@app.post("/search")
def search(req: SearchRequest):
    qvec = embed_text(req.query)  # pode ser None
    results = hybrid_search(req.query, qvec, k=req.k,
                            categoria=req.categoria, tags=req.tags)
    return {"results": results}
