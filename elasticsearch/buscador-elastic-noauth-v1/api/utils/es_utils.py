import os, requests

ES_URL = os.getenv("ES_URL", "http://elasticsearch:9200")
INDEX = "docs-buscador"
DIMS = 384  # MiniLM

def ensure_index():
    mapping = {
        "mappings": {
            "properties": {
                "title": {"type": "keyword"},
                "source": {"type": "keyword"},
                "path": {"type": "keyword"},
                "content": {"type": "text"},
                "content_vector": {"type": "dense_vector", "dims": DIMS, "similarity": "cosine"}
            }
        }
    }
    r = requests.get(f"{ES_URL}/{INDEX}")
    if r.status_code == 404:
        requests.put(f"{ES_URL}/{INDEX}", json=mapping).raise_for_status()

def bulk_index(items, embeddings):
    # build ndjson for _bulk
    lines = []
    for it, emb in zip(items, embeddings):
        doc = {
            "title": it.get("title") or "",
            "source": it.get("source") or "",
            "path": it.get("path") or "",
            "content": it["text"],
            "content_vector": emb,
        }
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

# local json dumps avoiding extra dependencies
import json
def json_dumps(obj):
    return json.dumps(obj, ensure_ascii=False, separators=(",",":"))
