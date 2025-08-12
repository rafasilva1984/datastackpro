
# Open Observability Unified 🚀

Este repositório demonstra um ecossistema de observabilidade completo, integrado com Elastic Stack, Prometheus, Loki, Grafana e Alertmanager, permitindo coleta, visualização e alerta de métricas, logs e eventos de forma unificada.

---

## 📦 Componentes

### 1. Elasticsearch
Banco de dados para armazenamento e busca de logs e métricas. Utilizado para análise detalhada, dashboards e insights.

### 2. Kibana
Interface de visualização para dados do Elasticsearch, criação de dashboards e exploração de logs.

### 3. Loki
Armazenamento otimizado de logs, com integração nativa ao Grafana.

### 4. Prometheus
Coleta e armazena métricas numéricas em série temporal. Ideal para monitoramento de infraestrutura e aplicações.

### 5. Alertmanager
Gerencia e envia alertas originados do Prometheus, com suporte a rotas, silenciamento e agrupamento.

### 6. Grafana
Painéis interativos unificando dados de métricas, logs e traces.

### 7. SampleApp
Aplicação simulada que gera métricas e logs para testes do ecossistema.

### 8. Predictor
Serviço que expõe métricas para simular monitoramento de modelo de machine learning.

---

## 🔍 Fluxo de Dados

1. **SampleApp** → Envia métricas para Prometheus e logs para Loki.
2. **Predictor** → Envia métricas para Prometheus.
3. **Prometheus** → Armazena métricas e dispara alertas para o Alertmanager.
4. **Loki** → Armazena logs consultáveis pelo Grafana.
5. **Elasticsearch + Kibana** → Coleta e visualiza logs/alertas detalhados.
6. **Grafana** → Unifica visualização de métricas, logs e alertas.

---

## 📊 Geração de Insights

- **Identificar Gargalos**: Usando métricas de CPU, memória e latência do Prometheus.
- **Investigar Problemas**: Consultando logs no Loki e Elasticsearch.
- **Correlacionar Eventos**: Painéis no Grafana mostrando logs e métricas no mesmo período.
- **Receber Alertas**: Configurações no Alertmanager notificam sobre eventos críticos.

---

## 🔔 Simulação de Alertas

Para validar o funcionamento do **Prometheus** + **Alertmanager**, siga os passos abaixo para simular alertas de forma controlada.

### 1️⃣ Simulação de Alta CPU
Força carga de CPU no container `sampleapp` para disparar alerta de **Alta Utilização de CPU**.
```bash
docker compose exec sampleapp sh -c 'yes > /dev/null &'
```
> Para parar a carga:
```bash
docker compose exec sampleapp pkill yes
```

---

### 2️⃣ Simulação de Falha de Serviço
Interrompe o serviço `predictor` para disparar alerta de **Instância Inativa**.
```bash
docker compose stop predictor
```
> Para voltar ao normal:
```bash
docker compose start predictor
```

---

### 3️⃣ Simulação de Latência Alta
Envia múltiplas requisições simultâneas para aumentar a latência e gerar alerta de **Atraso no Tempo de Resposta**.
```bash
for i in {1..200}; do
  curl -s http://localhost:3001/login >/dev/null &
  curl -s http://localhost:3001/checkout >/dev/null &
  curl -s http://localhost:3001/error >/dev/null || true &
done
wait
```

---

💡 **Dica:** Após executar cada simulação, acesse o Alertmanager para verificar o disparo do alerta:  
👉 [http://localhost:9093](http://localhost:9093)

---

## 📚 Uso Educacional

Este repositório serve como um **guia prático de estudo** para entender o funcionamento de um ecossistema de observabilidade real, cobrindo:

- Coleta de métricas e logs
- Visualização integrada
- Criação e teste de alertas
- Análise de incidentes
