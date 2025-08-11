# Open Observability – Plataforma 100% Open com **Elastic + Grafana Stack + OTel**

**Objetivo do Case**  
Criar uma **plataforma de observabilidade unificada**, 100% em containers, que combina o **melhor do ecossistema open**:
- **Métricas & Alertas** com **Prometheus** (previsão pró-ativa via serviço próprio)
- **Logs** em **dois destinos**: **Loki** (rápida exploração) **e Elasticsearch** (pesquisa/analytics e Kibana)
- **Traces** com **OpenTelemetry → Tempo**
- **Visualização** com **Grafana** (técnico) e **Kibana** (exploração de logs no Elastic)

> O diferencial é a **inteligência preditiva**: um microserviço (*predictor*) estima “**em quantos segundos**” você atingirá um limiar de RPS. Isso permite **alertas antes** do problema acontecer.

---

## Arquitetura (alto nível)

```
Carga -> SampleApp (Node.js) --OTLP--> OTel Collector -> Tempo (Traces)
        |-> Metrics (Prometheus client) -> Prometheus -----> Grafana (Dashboards/Alertas)
        |-> Logs (JSON) -> Promtail -> Loki ----------------> Grafana (Logs)
        |-> Logs (JSON) -> Filebeat -> Elasticsearch -------> Kibana (Discover/Visualize)
Predictor (Python) <-- Prometheus API  ---------------------> Expondo métrica preditiva
```

---

## Requisitos
- Docker e Docker Compose

## Passo a Passo (5 minutos)
1. **Subir a stack**  
   ```bash
   docker compose up -d --build
   ```
   Aguarde ~30–60s para provisionamento.

2. **Acessos rápidos**
   - Grafana: http://localhost:3000 (admin / admin)  
   - Prometheus: http://localhost:9090  
   - Alertmanager: http://localhost:9093  
   - Kibana: http://localhost:5601  
   - Elasticsearch: http://localhost:9200  
   - SampleApp: http://localhost:3001/health  
   - Predictor: http://localhost:8000/health  

3. **Dashboard pronto (Grafana)**  
   Abra o painel **“Open Observability – Visão Unificada (com Elasticsearch)”**.  
   Você verá:
   - **RPS** (Prometheus)
   - **Tempo previsto (s)** para atingir o limiar (métrica `time_to_threshold_seconds`)
   - **Logs (Loki)** em tempo real
   - **Contagem de logs por status (Elasticsearch)**

4. **Explorar logs no Kibana (Elasticsearch)**
   - Acesse **Kibana → Discover**
   - Crie um **Data View** com `sampleapp-logs-*` e campo de tempo `@timestamp`
   - Explore campos `route`, `status`, `duration_ms`, `level`, `msg`, `service.name`

5. **Teste os alertas preditivos**
   - Regra no Prometheus: **ImminentRequestSaturation** dispara quando `time_to_threshold_seconds < 600` por 2m
   - Aumente carga ajustando o `sleep` em `scripts/load.sh` (diminua o intervalo)

---

## Componentes e responsabilidades
- **Elasticsearch (8.x) + Kibana**: pesquisa e análise de logs (`sampleapp-logs-*`), visual/Discover
- **Filebeat**: leitor de `/var/log/sampleapp/app.log` → envia para Elasticsearch (mapeamento automático)
- **Loki + Promtail**: exploração de logs rápida e barata (complementar ao Elastic)
- **Prometheus + Alertmanager**: métricas e alertas baseados em regra
- **Predictor (Python)**: previsão por tendência linear do `rate(sampleapp_http_requests_total[5m])`
- **Grafana**: visão unificada (Prometheus/Loki/Tempo/Elasticsearch)
- **Tempo**: armazenamento de traces OTLP
- **OTel Collector**: gateway para traces e métricas por OTLP
- **SampleApp (Node.js)**: gera métricas, logs (JSON) e traces
- **Loadgen**: envia tráfego automaticamente

---

## Como funciona a previsão
O serviço **predictor** usa a API do Prometheus para ler o histórico do **RPS**, ajusta uma reta (regressão linear) e calcula **em quantos segundos** o valor atingirá o **limiar** (default `50`).  
- Métrica: `time_to_threshold_seconds{metric="sampleapp_rps", threshold="50"}`
- **Alerta**: dispara quando `< 600s` por **2m**.

Personalize no `docker-compose.yml` (serviço `predictor`):
- `TARGET_EXPR` (PromQL), `TARGET_THRESHOLD`, `POLL_SECONDS`.

---

## Troubleshooting
- **Kibana sem dados**: confirme `filebeat` rodando e volume `sampleapp-logs` montado na app e no filebeat.
- **Sem dashboards no Grafana**: veja logs do container `grafana` (provisionamento de datasources e dashboards).
- **Sem traces**: verifique `otel-collector` e `tempo`, e log `OpenTelemetry SDK started` na `sampleapp`.
- **Sem previsão**: cheque `http://localhost:8000/health` e alcance do Prometheus pelo `predictor`.

---

## Observações de licença
- **Elasticsearch/Kibana** (Elastic License 2) são **gratuitos** para uso e adequados a PoC.  
- Loki, Prometheus, Grafana, Tempo, OTel Collector são projetos **open source**.

---

## Parar e remover
```bash
docker compose down -v
```
