# 🔎 Buscador Unificado (Elastic 8.x **sem autenticação**) — v1

PoC pronta para rodar: **Elasticsearch + Kibana + API FastAPI + UI Streamlit**.
Sem tokens e sem enrollment: o Elasticsearch sobe com **`xpack.security.enabled=false`**,
e o Kibana se conecta automaticamente.

## ✨ O que vem pronto
- **Elasticsearch 8.x** sem autenticação (single-node) + **Kibana**
- **API** (`/ingest`, `/search`) que cria índice, gera embeddings e faz **KNN** no ES
- **UI** com 2 abas: Ingestão (botão) e Busca
- **Embeddings PT-BR** com `paraphrase-multilingual-MiniLM-L12-v2` (384 dims)
- **Docs de exemplo** em `data/docs/`

---
## ⚙️ Requisitos
- Docker + Docker Compose v2
- Portas livres: **9200** (ES), **5601** (Kibana), **8000** (API), **8501** (UI)

---
## 🚀 Como rodar
```bash
# 1) preparar variáveis
cp .env.example .env

# 2) subir tudo (ES + Kibana + API + UI)
docker compose up -d --build

# 3) abrir a UI
# http://localhost:8501
# Aba "Ingestão" → clique em "Rodar ingestão"
# Aba "Busca" → pesquise em PT-BR
```

---
## 🔧 Configurações
Edite `.env` para ajustar:
- `ES_URL` (padrão `http://elasticsearch:9200` para containers)
- `MODEL_NAME` (embeddings multilíngue por padrão)
- Pastas (`LOCAL_DOCS_DIR`)

---
## 🧹 Reset (começar do zero)
```bash
docker compose down -v
docker compose up -d --build
```

---
⚠️ **Atenção**: desabilitar segurança é apenas para PoC local.
Não use em produção.
