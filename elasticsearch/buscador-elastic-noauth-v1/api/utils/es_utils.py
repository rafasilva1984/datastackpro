import os, requests, json

ES_URL = os.getenv("ES_URL", "http://elasticsearch:9200")
INDEX = os.getenv("INDEX_NAME", "docs-buscador")
DIMS = 384  # MiniLM

def json_dumps(obj):
    return json.dumps(obj, ensure_ascii=False, separators=(",",":"))

def ensure_index():
    # cria o índice se não existir; content_vector é opcional
    mapping = {
        "mappings": {
            "properties": {
                "title": {"type": "keyword"},
                "source": {"type": "keyword"},
                "path": {"type": "keyword"},
                "content": {"type": "text"},
                # Se não houver vetor, ES ignora; se houver, KNN funciona
                "content_vector": {"type": "dense_vector", "dims": DIMS, "similarity": "cosine"}
            }
        }
    }
    r = requests.get(f"{ES_URL}/{INDEX}")
    if r.status_code == 404:
        requests.put(f"{ES_URL}/{INDEX}", json=mapping).raise_for_status()

def bulk_index(items, embeddings=None):
    """Indexa; se embeddings=None, vai sem vetor (full-text only)."""
    lines = []
    use_vectors = embeddings is not None
    for i, it in enumerate(items):
        doc = {
            "title": it.get("title") or "",
            "source": it.get("source") or "",
            "path": it.get("path") or "",
            "content": it["text"],
        }
        if use_vectors:
            doc["content_vector"] = embeddings[i]
        lines.append({ "index": { "_index": INDEX } })
        lines.append(doc)
    data = "\n".join([json_dumps(x) for x in lines]) + "\n"
    r = requests.post(f"{ES_URL}/_bulk", data=data, headers={"Content-Type": "application/x-ndjson"})
    r.raise_for_status()

def knn_search(query_vector, k=5):
    body = {
        "knn": {
            "field": "content_vector",
            "query_vector": query_vector,
            "k": k,
            "num_candidates": max(50, k*10)
        },
        "_source": ["title","source","path","content"]
    }
    r = requests.post(f"{ES_URL}/{INDEX}/_search", json=body)
    if r.status_code == 400:
        # Provavelmente índice sem vetores; caímos para full-text
        return text_search(" ", k)  # retorna vazio amigável
    r.raise_for_status()
    hits = r.json().get("hits", {}).get("hits", [])
    out = []
    for i, h in enumerate(hits, start=1):
        src = h.get("_source", {})
        out.append({
            "rank": i,
            "score": h.get("_score"),
            "document": src.get("content", ""),
            "metadata": {k: src.get(k) for k in ("title","source","path")}
        })
    return out

def text_search(query_text, k=5):
    body = {
        "query": { "match": { "content": query_text } },
        "_source": ["title","source","path","content"],
        "size": k
    }
    r = requests.post(f"{ES_URL}/{INDEX}/_search", json=body)
    r.raise_for_status()
    hits = r.json().get("hits", {}).get("hits", [])
    out = []
    for i, h in enumerate(hits, start=1):
        src = h.get("_source", {})
        out.append({
            "rank": i,
            "score": h.get("_score"),
            "document": src.get("content", ""),
            "metadata": {k: src.get(k) for k in ("title","source","path")}
        })
    return out
