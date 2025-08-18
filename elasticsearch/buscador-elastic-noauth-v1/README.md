# 🔎 Buscador Unificado (Elastic 8.x **sem autenticação**) — v1

PoC pronta para rodar: **Elasticsearch + Kibana + API FastAPI + UI Streamlit**.  
Sem tokens e sem enrollment: o Elasticsearch sobe com **`xpack.security.enabled=false`**, e o Kibana se conecta automaticamente.

---

## ✨ O que vem pronto
- **Elasticsearch 8.x** sem autenticação (single-node) + **Kibana**
- **API** (`/ingest`, `/search`) que cria índice, gera embeddings e faz **KNN** no ES
- **UI** com 2 abas: **Ingestão (botão)** e **Busca**
- **Embeddings PT-BR** com `paraphrase-multilingual-MiniLM-L12-v2` (384 dims)
- **Docs de exemplo** em `data/docs/`

---

## ⚙️ Requisitos
- Docker + Docker Compose v2
- Portas livres:  
  - **9200** → Elasticsearch  
  - **5601** → Kibana  
  - **8000** → API  
  - **8501** → UI  

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
- `ES_URL` → padrão `http://elasticsearch:9200` (quando roda via containers)
- `MODEL_NAME` → embeddings multilíngue por padrão
- `LOCAL_DOCS_DIR` → pasta de documentos para ingestão

---

## 🧹 Reset (começar do zero)
```bash
docker compose down -v
docker compose up -d --build
```

---

## 🛠️ Erros Comuns & Soluções

### ❌ Kibana não sobe
- Verifique se a porta **5601** está livre:  
  ```bash
  lsof -i:5601
  ```
- Se houver outro processo, finalize ou altere a porta no `docker-compose.yml`.

---

### ❌ API retorna erro de conexão com Elasticsearch
- Confirme se o ES está **rodando**:
  ```bash
  curl http://localhost:9200
  ```
- Se não responder, rode:
  ```bash
  docker compose logs elasticsearch
  ```

---

### ❌ Problemas de cache no Docker
- Use **build sem cache**:
  ```bash
  docker compose build --no-cache
  docker compose up -d
  ```

---

### ❌ UI (Streamlit) não abre no navegador
- Verifique logs:
  ```bash
  docker compose logs search-ui
  ```
- Se for erro de dependência Python, rode novamente o build:
  ```bash
  docker compose up -d --build search-ui
  ```

---

## 💡 Dicas Úteis
- Para **adicionar novos documentos**, coloque arquivos `.txt` em `data/docs/` e rode a aba **Ingestão** da UI novamente.  
- Para **resetar apenas o índice** no ES:
  ```bash
  curl -X DELETE "http://localhost:9200/docs"
  ```
- Para acompanhar os logs em tempo real:
  ```bash
  docker compose logs -f
  ```

---

## ❓ FAQ
**1. Posso usar em produção?**  
🚫 Não. Essa PoC desabilita autenticação do Elasticsearch. É apenas para estudo/local.  

**2. Posso trocar o modelo de embeddings?**  
Sim, altere a variável `MODEL_NAME` no `.env`.  

**3. Posso rodar sem Docker?**  
Pode, mas exigirá instalar manualmente Elasticsearch, Kibana e dependências Python.  

---

📌 **Atenção**: desabilitar segurança é apenas para PoC local. Não use em produção.  
