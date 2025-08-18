# 🔎 Buscador Unificado (Elastic 8.x **sem autenticação**) — v1

PoC pronta para rodar: **Elasticsearch + Kibana + API FastAPI + UI Streamlit**.  
Sem tokens e sem enrollment: o Elasticsearch sobe com **`xpack.security.enabled=false`**,  
e o Kibana se conecta automaticamente.

---

## ✨ O que vem pronto
- **Elasticsearch 8.x** sem autenticação (single-node) + **Kibana**
- **API** (`/ingest`, `/ingest_confluence`, `/search`) que cria índice, gera embeddings e faz **KNN** no ES
- **UI** com 3 abas:
  - **Ingestão Local** → carrega docs de `data/docs/`
  - **Ingestão Confluence** → puxa páginas via API
  - **Busca** → pesquisa em PT-BR
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
# Aba "Ingestão Local" → clique em "Rodar ingestão"
# Aba "Ingestão Confluence" → clique em "Rodar ingestão Confluence"
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

---

## 📑 Integração com Confluence

Além de usar a pasta `data/docs/`, você pode integrar diretamente com **Confluence** e buscar páginas internas.  
O botão **"Rodar ingestão Confluence"** já está disponível na UI.

### 1) Criar API Token no Atlassian
- Acesse: [https://id.atlassian.com/manage/api-tokens](https://id.atlassian.com/manage/api-tokens)  
- Clique em **Create API token**  
- Guarde o **token** e o **usuário de login (e-mail)**  

### 2) Ajustar variáveis no `.env`
```env
# URL da instância Confluence (exemplo: https://empresa.atlassian.net/wiki)
CONFLUENCE_URL=https://empresa.atlassian.net/wiki
CONFLUENCE_USER=seu.email@empresa.com
CONFLUENCE_TOKEN=token_aqui
CONFLUENCE_SPACE=OBS  # código do espaço que você deseja buscar
```

### 3) Dependência já incluída
O projeto já contém no `requirements.txt`:
```
atlassian-python-api==3.41.2
```

### 4) Uso
- Subir os containers normalmente  
- Abrir a **UI** (`http://localhost:8501`)  
- Clicar em **Rodar ingestão Confluence** para puxar páginas do espaço configurado  
- Buscar termos diretamente na aba **Busca**

---

💡 Dessa forma, você pode escolher:  
- **Docs locais** → PoC rápida  
- **Confluence** → Casos reais na sua empresa
