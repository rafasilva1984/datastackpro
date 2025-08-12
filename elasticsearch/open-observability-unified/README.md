# 📊 Open Observability Unified – Guia Completo

Este projeto demonstra um ecossistema completo de observabilidade unificado, com coleta, armazenamento, análise e visualização de métricas, logs e traces em um único stack.  
Ele integra **Prometheus**, **Grafana**, **Loki**, **Tempo**, **Elasticsearch**, **Kibana**, **Alertmanager** e uma aplicação de exemplo (*SampleApp*) instrumentada.

---

## 🧭 Passo a passo rápido (iniciante)

### 1) Pré‑requisitos
- Instale **Docker Desktop** (Windows/Mac) ou **Docker Engine** + **Docker Compose** (Linux).
- Instale **Git**.

### 2) Clonar este repositório
```bash
# via HTTPS (recomendado para iniciantes)
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
Espere até todos os containers ficarem em **(healthy/Up)**:
```bash
docker compose ps
```

### 5) Acessar as interfaces
- Grafana: [http://localhost:3000](http://localhost:3000)  (login: `admin` / senha: `admin`)
- Prometheus: [http://localhost:9090](http://localhost:9090)
- Alertmanager: [http://localhost:9093](http://localhost:9093)
- Loki (API): [http://localhost:3100](http://localhost:3100)
- Tempo (traces): [http://localhost:3200](http://localhost:3200)
- Elasticsearch: [http://localhost:9200](http://localhost:9200)
- Kibana: [http://localhost:5601](http://localhost:5601)
- SampleApp (exposta): [http://localhost:3001/health](http://localhost:3001/health)

### 6) Gerar dados (opcional, mas recomendado)
```bash
# gerar tráfego na app por 30s
for i in {1..200}; do
  curl -s http://localhost:3001/login >/dev/null
  curl -s http://localhost:3001/checkout >/dev/null
  curl -s http://localhost:3001/error >/dev/null || true
done
```

### 7) Validar rapidamente
- **Prometheus → /targets:** todos `UP`
- **Grafana → Dashboards:** RPS/erros aparecendo
- **Loki (via Grafana Explore):** `{job="sampleapp"}` mostra logs recentes
- **Alertmanager → /#/alerts:** vazio (normal). Para **simular**:
  - Pare a app por 70s: `docker compose stop sampleapp`
  - Depois ligue de novo: `docker compose start sampleapp`

---

## 🔍 Componentes do ecossistema

### **Prometheus**
- Coleta métricas de serviços, aplicações e infraestrutura via *pull*.
- Configurado em `prometheus.yml` com *scrape intervals* e *targets*.
- Pode gerar alertas com base em regras no arquivo `alert.rules.yml`.

### **Alertmanager**
- Recebe alertas do Prometheus e envia notificações (email, Slack, Teams, etc.).
- Configurado em `alertmanager.yml` com rotas e receptores.
- Interface: [http://localhost:9093](http://localhost:9093).

### **Grafana**
- Visualização de métricas, logs e traces em painéis dinâmicos.
- Conecta ao Prometheus, Loki, Tempo e Elasticsearch como *data sources*.
- Dashboards prontos incluídos neste projeto.

### **Loki**
- Armazena e indexa logs com baixo custo.
- Consultas via Grafana Explore usando a linguagem LogQL.

### **Tempo**
- Armazena traces distribuídos (APM).
- Recebe spans via OpenTelemetry.

### **Elasticsearch + Kibana**
- Armazenamento e visualização avançada de dados (métricas, logs, traces).
- Kibana fornece interface para pesquisa, dashboards e alertas.

### **SampleApp**
- Aplicação Node.js instrumentada com métricas, logs e traces.
- Exposta na porta `3001` para testes e geração de carga.

---

## 📢 Simulando alertas

Três exemplos prontos para simulação:

1️⃣ **Parar a aplicação para simular indisponibilidade**  
```bash
docker compose stop sampleapp
sleep 70
docker compose start sampleapp
```

2️⃣ **Aumentar o tempo de resposta artificialmente**  
```bash
for i in {1..50}; do curl -s http://localhost:3001/error >/dev/null; done
```

3️⃣ **Gerar alto volume de requisições**  
```bash
for i in {1..500}; do curl -s http://localhost:3001/login >/dev/null; done
```

---

## 📚 Estudo e insights
- Explore queries no Prometheus e no Grafana para identificar gargalos.
- Use Loki para buscar logs por nível (`level="error"`) e origem (`job="sampleapp"`).
- Acompanhe traces no Tempo para entender o fluxo de requisições.
- Combine métricas, logs e traces para diagnóstico rápido.

---
