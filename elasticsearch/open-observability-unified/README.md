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

## ⚙️ Plugin Zabbix no Grafana: instalação manual

Devido a problemas de **certificado SSL inválido** no container oficial, o plugin **Zabbix App para Grafana** é instalado manualmente neste projeto.

### 🔧 Etapas automatizadas pelo Dockerfile
1. O plugin `alexanderzobnin-zabbix-app` é descompactado previamente no diretório `grafana/zabbix/`
2. O Dockerfile copia o conteúdo descompactado para `/var/lib/grafana/plugins/zabbix`
3. O plugin fica disponível automaticamente ao acessar o Grafana

### 📝 Arquivos relevantes
- `grafana/Dockerfile` → Customização da imagem do Grafana
- `grafana/zabbix/alexanderzobnin-zabbix-app/` → Plugin Zabbix descompactado

**⚠️ Caso queira atualizar o plugin no futuro, baixe manualmente em:**  
https://grafana.com/grafana/plugins/alexanderzobnin-zabbix-app/

---

## 🔧 Ajustes manuais obrigatórios

Após subir o ambiente, é **necessário executar manualmente as seguintes etapas** para o correto funcionamento do Grafana com o Zabbix e Elasticsearch:

### 1. Ajustar os Hosts no Zabbix
- Acesse o frontend do Zabbix: [http://localhost:8081](http://localhost:8081)
- Vá em **Configuration > Hosts**
- Edite os hosts existentes
- Altere os nomes para `zbx-agent1`, `zbx-agent2`, `zbx-agent3`
- Certifique-se que o agente está ativo e escutando na porta padrão (10050)

### 2. Criar novo datasource Zabbix no Grafana
- Acesse: [http://localhost:3000](http://localhost:3000)
- Vá em **Connections > Data Sources**
- Clique em **Add data source**
- Selecione **Zabbix**
- Configure a URL:
  ```
  http://zabbix-web:8080/api_jsonrpc.php
  ```
- Login: `Admin`, Senha: `zabbix`
- Clique em **Save & Test**

> ⚠️ O datasource provisionado automaticamente pode estar bloqueado para edição. A criação manual garante o funcionamento.

### 3. Criar novo datasource Elasticsearch no Grafana
- Ainda em **Data Sources**, clique em **Add data source**
- Selecione **Elasticsearch**
- URL:
  ```
  http://elasticsearch:9200
  ```
- Index pattern: `filebeat-*`
- Time field: `@timestamp`
- Salve e teste a conexão

---

## ✅ Validação do ambiente completo

Após subir os serviços com `docker compose up -d --build`, siga este checklist:

### 🔎 Verificar URLs (todas devem estar acessíveis):
- [x] Grafana em http://localhost:3000
- [x] Zabbix frontend em http://localhost:8081
- [x] Kibana em http://localhost:5601
- [x] Prometheus em http://localhost:9090
- [x] Tempo em http://localhost:3200
- [x] Loki em http://localhost:3100
- [x] Alertmanager em http://localhost:9093
- [x] SampleApp em http://localhost:3001/health

### 🧪 Verificar dashboards no Grafana:
- Dashboard SampleApp (métricas + logs + traces)
- Dashboard Elasticsearch Logs
- Dashboard Zabbix Infraestrutura (⚠️ após configurar o novo datasource)

### 🔐 Testar logins
- Grafana: `admin` / `admin`
- Zabbix: `Admin` / `zabbix`
- Elasticsearch: `elastic` / `changeme`

### 📊 Testar ingestão de dados
```bash
bash sampleapp/scripts/load.sh
```

---

## 🔍 Componentes do ecossistema

### 🟢 Prometheus
- Coleta métricas via *pull*
- Regras de alerta: `alert.rules.yml`

**API exemplo:**
```bash
curl "http://localhost:9090/api/v1/query?query=up"
```

### 🚨 Alertmanager
- Envia alertas definidos no Prometheus

**API exemplo:**
```bash
curl "http://localhost:9093/api/v2/alerts"
```

### 📈 Grafana
- Dashboards e unificação visual

### 📄 Loki
- Logs estruturados via Filebeat

**Consulta via API:**
```bash
curl -G "http://localhost:3100/loki/api/v1/query" --data-urlencode 'query={job="sampleapp"}'
```

### 🧵 Tempo
- Traces distribuídos OpenTelemetry

### 🔍 Elasticsearch + Kibana
- Logs e análises de observabilidade

**Exemplo:**
```bash
curl -u elastic:changeme "http://localhost:9200/_cat/indices?v"
```

### 🖥️ Zabbix
- Monitoramento tradicional de infraestrutura

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
- Combine métricas + logs + traces em dashboards unificados.
- Explore as APIs dos componentes para automações.
- O Zabbix é ideal para infra legada ou ambientes on-premises.
- Reconfigure o `docker-compose.yml` para novos testes.

---

## 🛠 Estrutura dos arquivos principais
- `docker-compose.yml` → Infraestrutura
- `prometheus.yml` → Coleta de métricas
- `alert.rules.yml` → Regras de alerta
- `grafana/` → Dashboards e plugin Zabbix
- `sampleapp/` → App instrumentado
- `zabbix/` → Configuração dos containers

---
