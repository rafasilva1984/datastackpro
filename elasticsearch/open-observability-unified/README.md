
# 📊 Open Observability Unified – Guia Completo

Este repositório reúne um **ecossistema completo de observabilidade** integrando métricas, logs e alertas com ferramentas amplamente utilizadas no mercado, permitindo **monitoramento unificado e proativo**.

---

## 🛠️ Arquitetura Geral

A solução é composta por:
- **Prometheus** → Coleta métricas de aplicações e serviços via *scraping*.
- **Alertmanager** → Recebe alertas do Prometheus e envia notificações.
- **Grafana** → Interface visual para dashboards e análise de métricas/logs.
- **Loki** → Coleta e indexa logs de forma eficiente.
- **SampleApp** → Aplicação de exemplo para gerar métricas e logs.
- **Predictor** → Serviço de previsão para gerar métricas simuladas.
- **Docker Compose** → Orquestra todos os serviços localmente.

---

## 🔍 Componentes e Funcionamento

### 1. **Prometheus**
- **Função:** Coleta métricas de endpoints configurados no `prometheus.yml`.
- **Como funciona:** Faz requisições HTTP periódicas (`scraping`) para URLs de serviços que expõem métricas no formato Prometheus.
- **Configuração-chave:**
  ```yaml
  scrape_configs:
    - job_name: 'sampleapp'
      static_configs:
        - targets: ['sampleapp:3000']
    - job_name: 'predictor'
      static_configs:
        - targets: ['predictor:8000']
  ```
- **Uso:** Métricas são armazenadas em banco de dados interno *time-series*.

---

### 2. **Alertmanager**
- **Função:** Recebe alertas do Prometheus e gerencia notificações.
- **Cenários de uso:** Avisar sobre picos de CPU, indisponibilidade de serviço, etc.
- **Fluxo:**  
  1. Prometheus detecta condição de alerta →  
  2. Envia para Alertmanager →  
  3. Alertmanager encaminha para e-mail, Slack, etc.

**Configuração de exemplo (`alertmanager.yml`):**
```yaml
route:
  receiver: 'default'
receivers:
  - name: 'default'
    email_configs:
      - to: 'meuemail@dominio.com'
```

---

### 3. **Grafana**
- **Função:** Visualizar métricas e logs de forma unificada.
- **Integrações neste projeto:**
  - **Prometheus** (métricas)
  - **Loki** (logs)
- **Uso prático:** Criar dashboards para CPU, memória, taxa de erros e muito mais.
- **Acesso:** [http://localhost:3000](http://localhost:3000) (login padrão: `admin/admin`).

---

### 4. **Loki**
- **Função:** Armazenar e consultar logs de forma rápida e econômica.
- **Configuração do Promtail (coletor de logs):**
```yaml
scrape_configs:
  - job_name: 'sampleapp'
    static_configs:
      - targets: ['localhost']
        labels:
          job: sampleapp
          __path__: /var/log/*.log
```
- **Uso prático:** Buscar logs específicos no Grafana com consultas como:
```logql
{job="sampleapp"} |= "ERROR"
```

---

### 5. **SampleApp**
- **Função:** Aplicação simples para simular um ambiente monitorado.
- **Endpoints principais:**
  - `/login` → Operação de login
  - `/checkout` → Operação de compra
  - `/error` → Gera erro proposital
- **Métricas expostas:** Número de logins, compras e erros.

---

### 6. **Predictor**
- **Função:** Gera métricas de previsão (ex: tempo estimado para evento).
- **Endpoint de métricas:** `/metrics`

---

## 🚀 Subindo o Ambiente

```bash
docker compose up -d
```

Verifique os serviços ativos:
```bash
docker compose ps
```

---

## 📡 Simulação de Carga

```bash
for i in {1..50}; do
  curl -s http://localhost:3001/login >/dev/null
  curl -s http://localhost:3001/checkout >/dev/null
  curl -s http://localhost:3001/error >/dev/null || true
done
```

---

## 🔔 Simulação de Alertas

Execute no Prometheus para simular:

**1. Alerta de CPU Alta**
```bash
curl -X POST http://localhost:9090/-/reload
```
*(Com regra configurada para CPU > 80%)*

**2. Alerta de Latência Alta**
Gerar carga artificial:
```bash
for i in {1..200}; do curl -s http://localhost:3001/login; done
```

**3. Alerta de Serviço Fora**
```bash
docker compose stop sampleapp
```

---

## 📈 Geração de Insights
- **Dashboards:** Combine métricas do Prometheus com logs do Loki.
- **Correlação:** Use o mesmo `job` ou `instance` para cruzar dados.
- **Técnica prática:**  
  1. Identificar pico de erros →  
  2. Filtrar logs do mesmo intervalo →  
  3. Mapear causa raiz.

---

## 📚 Guia de Estudos
1. Entender coleta de métricas (Prometheus).
2. Criar consultas no Prometheus UI.
3. Integrar e explorar dashboards no Grafana.
4. Consultar logs no Loki com LogQL.
5. Criar regras de alerta no Prometheus e integrar no Alertmanager.

---

## 📌 Referências
- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)
- [Loki Docs](https://grafana.com/docs/loki/)
- [Alertmanager Docs](https://prometheus.io/docs/alerting/latest/alertmanager/)
