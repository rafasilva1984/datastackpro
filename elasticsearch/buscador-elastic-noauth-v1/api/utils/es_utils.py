import os, requests, json
from typing import List, Dict, Optional

ES_URL = os.getenv("ES_URL", "http://elasticsearch:9200")
INDEX = os.getenv("INDEX_NAME", "docs-buscador")
DIMS = 384  # MiniLM

def _jd(obj):  # json dumps compacto
    return json.dumps(obj, ensure_ascii=False, separators=(",",":"))

def ensure_index():
    """Cria o índice se não existir. Inclui campos extras para filtros/histórico."""
    mapping = {
        "mappings": {
            "properties": {
                "title":   {"type":"keyword"},
                "source":  {"type":"keyword"},
                "path":    {"type":"keyword"},
                "content": {"type":"text"},
                "categoria":{"type":"keyword"},
                "tags":     {"type":"keyword"},
                "ingested_at":{"type":"date"},
                # Vetor é opcional (quando embeddings estiverem disponíveis)
                "content_vector":{"type":"dense_vector","dims":DIMS,"similarity":"cosine"}
            }
        }
    }
    r = requests.get(f"{ES_URL}/{INDEX}")
    if r.status_code == 404:
        requests.put(f"{ES_URL}/{INDEX}", json=mapping).raise_for_status()

def bulk_index(items: List[Dict], embeddings: Optional[List[List[float]]] = None):
    """
    Indexa em _bulk. Se embeddings=None, indexa sem vetor (full-text).
    Aceita metadados opcionais: categoria, tags (lista/str), ingested_at (ISO8601).
    """
    use_vec = embeddings is not None
    lines = []
    for i, it in enumerate(items):
        doc = {
            "title": it.get("title") or "",
            "source": it.get("source") or "",
            "path": it.get("path") or "",
            "content": it["text"],
        }
        # metadados opcionais
        if "categoria" in it: doc["categoria"] = it["categoria"]
        if "tags" in it:      doc["tags"] = it["tags"]
        if "ingested_at" in it: doc["ingested_at"] = it["ingested_at"]

        if use_vec:
            doc["content_vector"] = embeddings[i]
        lines.append({"index": {"_index": INDEX}})
        lines.append(doc)
    data = "\n".join(_jd(x) for x in lines) + "\n"
    r = requests.post(f"{ES_URL}/_bulk", data=data, headers={"Content-Type":"application/x-ndjson"})
    r.raise_for_status()

def text_search(q: str, k: int = 5, categoria: Optional[str] = None, tags: Optional[List[str]] = None):
    """Full-text com highlight e filtros opcionais."""
    filt = []
    if categoria: filt.append({"term":{"categoria":categoria}})
    if tags:      filt.append({"terms":{"tags":tags}})

    body = {
        "size": k,
        "query": {
            "bool": {
                "must": [
                    {"multi_match": {
                        "query": q,
                        "fields": ["content^2", "title^4"],  # boost no título e conteúdo
                        "type": "best_fields"
                    }}
                ],
                "filter": filt
            }
        },
        "highlight": {
            "fields": {"content": {"fragment_size": 180, "number_of_fragments": 1}}
        },
        "_source": ["title","source","path","content","categoria","tags"]
    }
    r = requests.post(f"{ES_URL}/{INDEX}/_search", json=body)
    r.raise_for_status()
    hits = r.json().get("hits", {}).get("hits", [])
    out = []
    for i, h in enumerate(hits, start=1):
        src = h.get("_source", {})
        hl  = (h.get("highlight", {}) or {}).get("content", [])
        snippet = hl[0] if hl else src.get("content","")[:240]
        out.append({
            "id": h.get("_id"),
            "rank": i,
            "score": h.get("_score"),
            "document": snippet,
            "metadata": {k: src.get(k) for k in ("title","source","path","categoria","tags")}
        })
    return out

def knn_search(query_vector: List[float], k: int = 5, categoria: Optional[str] = None, tags: Optional[List[str]] = None):
    """KNN puro (com filtros). Depois dá para fazer highlight pelos IDs, se quiser."""
    filt = []
    if categoria: filt.append({"term":{"categoria":categoria}})
    if tags:      filt.append({"terms":{"tags":tags}})

    body = {
        "knn": {
            "field": "content_vector",
            "query_vector": query_vector,
            "k": k,
            "num_candidates": max(50, k*10)
        },
        "query": {"bool": {"filter": filt}} if filt else {"match_all": {}},
        "_source": ["title","source","path","content","categoria","tags"]
    }
    r = requests.post(f"{ES_URL}/{INDEX}/_search", json=body)
    if r.status_code == 400:
        # Índice sem vetores → sem KNN
        return []
    r.raise_for_status()
    hits = r.json().get("hits", {}).get("hits", [])
    out = []
    for i, h in enumerate(hits, start=1):
        src = h.get("_source", {})
        snippet = src.get("content","")[:240]
        out.append({
            "id": h.get("_id"),
            "rank": i,
            "score": h.get("_score"),
            "document": snippet,
            "metadata": {k: src.get(k) for k in ("title","source","path","categoria","tags")}
        })
    return out

def hybrid_search(q_text: str, q_vec: Optional[List[float]], k: int = 5,
                  categoria: Optional[str] = None, tags: Optional[List[str]] = None):
    """
    Junta text_search + knn_search (se vetor existir).
    Normaliza scores e gera ranking único.
    """
    txt = text_search(q_text, k=max(k, 8), categoria=categoria, tags=tags)
    knn = knn_search(q_vec,   k=max(k, 8), categoria=categoria, tags=tags) if q_vec else []

    # normalização simples
    def norm(lst):
        if not lst: return {}
        mx = max(h["score"] for h in lst if h["score"] is not None) or 1.0
        return {h["id"]: (h["score"]/mx) for h in lst if h["score"] is not None}

    nt, nk = norm(txt), norm(knn)
    ids = list({*(h["id"] for h in txt), *(h["id"] for h in knn)})

    # indexar por id p/ recuperar objetos
    by_id = {h["id"]: h for h in (txt+knn)}

    # pesos (ajuste como preferir)
    W_TXT, W_VEC = 0.5, 0.6 if q_vec else 0.0

    ranked = []
    for _id in ids:
        score = (nt.get(_id, 0.0)*W_TXT) + (nk.get(_id, 0.0)*W_VEC)
        h = by_id[_id].copy()
        h["score_hybrid"] = round(score, 6)
        ranked.append(h)

    ranked.sort(key=lambda x: x["score_hybrid"], reverse=True)
    return ranked[:k]
