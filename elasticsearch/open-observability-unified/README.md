# 📊 Open Observability Unified – Guia Completo e Didático

Este projeto demonstra um **ecossistema completo de observabilidade unificado**, cobrindo coleta, armazenamento, análise e visualização de **métricas, logs e traces**.  
A solução integra **Prometheus**, **Grafana**, **Loki**, **Tempo**, **Elasticsearch**, **Kibana**, **Alertmanager** e uma aplicação de exemplo (*SampleApp*) instrumentada com OpenTelemetry.

---

## 🧭 Passo a passo rápido (para iniciantes)

### 1) Pré‑requisitos
- **Docker Desktop** (Windows/Mac) ou **Docker Engine** + **Docker Compose** (Linux)
- **Git** instalado
- Conexão com a internet para baixar as imagens

### 2) Clonar este repositório
```bash
git clone https://github.com/rafasilva1984/datastackpro.git
cd datastackpro/elasticsearch/open-observability-unified
```

### 3) (Windows) Normalizar finais de linha
Para evitar problemas com scripts dentro do container:
```bash
git config core.autocrlf false
git config --global core.autocrlf false
```

### 4) Subir todo o ambiente
```bash
docker compose up -d --build
```
Verifique se todos os containers estão **Up**:
```bash
docker compose ps
```

### 5) Acessar as interfaces
- Grafana: [http://localhost:3000](http://localhost:3000)  (login: `admin` / senha: `admin`)
- Prometheus: [http://localhost:9090](http://localhost:9090)
- Alertmanager: [http://localhost:9093](http://localhost:9093)
- Loki (API): [http://localhost:3100](http://localhost:3100)
- Tempo (traces): [http://localhost:3200](http://localhost:3200)
- Elasticsearch: [http://localhost:9200](http://localhost:9200) (login: `elastic` / senha: `changeme`)
- Kibana: [http://localhost:5601](http://localhost:5601)
- SampleApp (testes): [http://localhost:3001/health](http://localhost:3001/health)

### 6) Gerar dados para teste
```bash
for i in {1..200}; do
  curl -s http://localhost:3001/login >/dev/null
  curl -s http://localhost:3001/checkout >/dev/null
  curl -s http://localhost:3001/error >/dev/null || true
done
```

---

## 🔍 Componentes do ecossistema

### **Prometheus**
- Coleta métricas via *pull* dos endpoints configurados em `prometheus.yml`.
- Suporta alertas definidos em `alert.rules.yml`.

**Consultar métricas via API:**
```bash
curl "http://localhost:9090/api/v1/query?query=up"
curl "http://localhost:9090/api/v1/query?query=rate(http_requests_total[1m])"
```

### **Alertmanager**
- Recebe e gerencia alertas do Prometheus.
- Configuração em `alertmanager.yml`.

**Consultar alertas via API:**
```bash
curl "http://localhost:9093/api/v2/alerts"
```

### **Grafana**
- Painéis e visualização de dados de múltiplas fontes (Prometheus, Loki, Tempo, Elasticsearch).
- Painéis prontos já incluídos.

### **Loki**
- Armazenamento e consulta de logs com baixo custo.
- Consultas via **LogQL**.

**Consultar via API:**
```bash
curl -sG "http://localhost:3100/loki/api/v1/query" --data-urlencode 'query={job="sampleapp"}' --data-urlencode 'limit=5'
```

### **Tempo**
- Armazenamento e busca de *traces*.
- Integrado via OpenTelemetry.

**Consultar traces (exemplo de busca por traceID):**
```bash
curl "http://localhost:3200/api/traces/<trace-id>"
```

### **Elasticsearch + Kibana**
- Armazenamento avançado para métricas, logs e traces.
- Kibana para exploração e dashboards.

**Consultar índices via API:**
```bash
curl -u elastic:changeme "http://localhost:9200/_cat/indices?v"
```

---

## 📢 Simulando alertas

### 1️⃣ Parar a aplicação (indisponibilidade)
```bash
docker compose stop sampleapp
sleep 70
docker compose start sampleapp
```

### 2️⃣ Aumentar tempo de resposta
```bash
for i in {1..50}; do curl -s http://localhost:3001/error >/dev/null; done
```

### 3️⃣ Alta carga de requisições
```bash
for i in {1..500}; do curl -s http://localhost:3001/login >/dev/null; done
```

---

## 📚 Dicas de estudo e uso
- Combine **Prometheus** (métricas), **Loki** (logs) e **Tempo** (traces) no Grafana para análises 360°.
- Explore o Kibana para filtros e dashboards mais complexos.
- Teste a API de cada ferramenta para entender como extrair dados programaticamente.
- Alterar configurações no `docker-compose.yml` permite mudar portas e adicionar integrações.

---

## 🛠 Estrutura do repositório
- `docker-compose.yml` → Sobe todos os serviços
- `prometheus.yml` → Configuração de coleta de métricas
- `alert.rules.yml` → Regras de alerta
- `alertmanager.yml` → Destinos e rotas de alerta
- `grafana/provisioning/` → Data sources e dashboards
- `loki-config.yml` → Configuração do Loki
- `tempo.yml` → Configuração do Tempo
- `sampleapp/` → Código da aplicação de exemplo

---

## 🚀 Troubleshooting
- **Loki vazio:** verifique se a `sampleapp` está gerando logs.
- **Prometheus sem targets UP:** acesse `http://localhost:9090/targets`.
- **Kibana não conecta:** confirme se o Elasticsearch está rodando (`docker compose logs elasticsearch`).

---
