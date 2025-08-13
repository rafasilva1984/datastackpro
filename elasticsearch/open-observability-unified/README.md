# 📊 Open Observability Unified – Guia Completo e Didático

Este projeto demonstra um **ecossistema completo de observabilidade unificado**, cobrindo coleta, armazenamento, análise e visualização de **métricas, logs e traces**.  
A solução integra **Prometheus**, **Grafana**, **Loki**, **Tempo**, **Elasticsearch**, **Kibana**, **Alertmanager**, **Zabbix** e uma aplicação de exemplo (*SampleApp*) instrumentada com OpenTelemetry.

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
- Grafana: [http://localhost:3000](http://localhost:3000) (login: `admin` / senha: `admin`)
- Prometheus: [http://localhost:9090](http://localhost:9090)
- Alertmanager: [http://localhost:9093](http://localhost:9093)
- Loki (API): [http://localhost:3100](http://localhost:3100)
- Tempo (traces): [http://localhost:3200](http://localhost:3200)
- Elasticsearch: [http://localhost:9200](http://localhost:9200) (login: `elastic` / senha: `changeme`)
- Kibana: [http://localhost:5601](http://localhost:5601)
- Zabbix (frontend): [http://localhost:8081](http://localhost:8081) (login: `Admin` / senha: `zabbix`)
- SampleApp: [http://localhost:3001/health](http://localhost:3001/health)

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

### 🟢 Prometheus
- Coleta métricas via *pull* dos endpoints configurados.
- Suporta alertas definidos em `alert.rules.yml`.

**API exemplo:**
```bash
curl "http://localhost:9090/api/v1/query?query=up"
```

### 🚨 Alertmanager
- Gerencia e envia notificações com base nas regras do Prometheus.

**API exemplo:**
```bash
curl "http://localhost:9093/api/v2/alerts"
```

### 📈 Grafana
- Painéis de visualização para Prometheus, Loki, Tempo, Elasticsearch e Zabbix.

### 📄 Loki
- Indexação de logs (via Promtail e Filebeat).

**API exemplo:**
```bash
curl -G "http://localhost:3100/loki/api/v1/query" --data-urlencode 'query={job="sampleapp"}'
```

### 🧵 Tempo
- Armazena traces distribuídos (OpenTelemetry).

### 🔍 Elasticsearch + Kibana
- Armazena logs estruturados da SampleApp e dashboards no Kibana.

**API exemplo:**
```bash
curl -u elastic:changeme "http://localhost:9200/_cat/indices?v"
```

### 🖥️ Zabbix
- Plataforma para monitoramento de infraestrutura e ativos físicos.

---

## 📢 Simulando alertas

### 1️⃣ Parar a aplicação
```bash
docker compose stop sampleapp
sleep 70
docker compose start sampleapp
```

### 2️⃣ Tempo de resposta elevado
```bash
for i in {1..50}; do curl -s http://localhost:3001/error >/dev/null; done
```

### 3️⃣ Carga elevada
```bash
for i in {1..500}; do curl -s http://localhost:3001/login >/dev/null; done
```

---

## 📚 Dicas de estudo
- Combine **métricas (Prometheus)**, **logs (Loki/Elasticsearch)** e **traces (Tempo)** no Grafana.
- Utilize o Zabbix para observabilidade de infraestrutura on-premises.
- Explore APIs de todos os componentes para criar integrações automatizadas.
- Modifique e reinicie serviços no `docker-compose.yml` para testar novos cenários.

---

## 🛠 Estrutura dos arquivos principais
- `docker-compose.yml` → Sobe todos os serviços
- `prometheus.yml` → Configuração de coleta
- `alert.rules.yml` → Regras de alerta
- `grafana/` → Dashboards e datasources
- `sampleapp/` → App de exemplo com logs e métricas
- `zabbix/` → Configuração do frontend e server Zabbix

---
