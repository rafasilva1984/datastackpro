
# Open Observability Unified

Este repositório é uma **prova de conceito** que integra as principais ferramentas de observabilidade em um ecossistema unificado.
O objetivo é permitir **monitoramento, análise, rastreamento e alertas** de forma centralizada, simulando um ambiente real de observabilidade.

---

## 📌 Visão Geral do Ecossistema

O ambiente é composto por:

- **Prometheus** → Coleta métricas numéricas de serviços e aplicações.
- **Grafana** → Interface visual para dashboards e análise de métricas e logs.
- **Loki** → Armazenamento e consulta de logs.
- **Tempo** → Rastreamento distribuído (distributed tracing).
- **Alertmanager** → Gerenciamento de alertas enviados pelo Prometheus.
- **SampleApp** → Aplicação de exemplo que gera métricas, logs e traces.
- **Predictor** → Serviço de exemplo que expõe métricas para Prometheus.
- **Elastic Stack (Opcional)** → Indexação e busca avançada de dados.

A comunicação entre essas ferramentas é orquestrada via **Docker Compose**.

---

## 📂 Estrutura do Projeto

```
open-observability-unified/
│── docker-compose.yml        # Orquestração dos containers
│── prometheus.yml             # Configuração do Prometheus
│── alert.rules.yml            # Regras de alerta
│── grafana/                   # Dashboards e datasources
│── loki-config.yml            # Configuração do Loki
│── tempo-config.yml           # Configuração do Tempo
│── sampleapp/                 # Código da aplicação de exemplo
│   ├── app.js                 
│   ├── Dockerfile
│   └── load.sh                 # Script para gerar carga
│── predictor/                 
│   ├── app.py                  
│   ├── requirements.txt
│── README.md                  
```

---

## ⚙️ Ferramentas e Funções

### **Prometheus**
- Coleta métricas expostas em endpoints `/metrics` das aplicações.
- Usa **scrape jobs** definidos no `prometheus.yml` para buscar métricas em intervalos configurados.
- Armazena dados temporariamente em seu banco interno de séries temporais.
- Pode enviar alertas para o **Alertmanager**.

📌 **Comando para consultar métricas diretamente**:
```bash
curl -s "http://localhost:9090/api/v1/query" --data-urlencode 'query=up'
```

---

### **Grafana**
- Painel visual que conecta-se ao Prometheus, Loki, Tempo e Elasticsearch.
- Permite criar dashboards unificados.
- Possui **datasources** pré-configurados para este ambiente.

📌 **Acesso**: [http://localhost:3000](http://localhost:3000) (usuário: admin / senha: admin)

---

### **Loki**
- Sistema de logs otimizado, inspirado no Prometheus, mas para texto.
- Coleta logs via push (promtail) ou APIs.
- Consultas com **LogQL**:
```bash
curl -sG "http://localhost:3100/loki/api/v1/query"   --data-urlencode 'query={job="sampleapp"}'   --data-urlencode 'limit=5'
```

---

### **Tempo**
- Solução para rastreamento distribuído.
- Permite ver o caminho de requisições e identificar gargalos.

📌 **Exemplo de uso**:
- Ao acessar a `SampleApp`, cada requisição gera um **trace** que pode ser visualizado no Grafana.

---

### **Alertmanager**
- Recebe alertas do Prometheus.
- Agrupa, deduplica e envia notificações para canais (e-mail, Slack, etc.).

📌 **Acesso**: [http://localhost:9093](http://localhost:9093)

---

## 🚀 Subindo o Ambiente

```bash
docker compose up -d
```

Verifique se os containers estão rodando:
```bash
docker compose ps
```

---

## 📊 Gerando Carga e Dados

Para popular o ambiente com métricas, logs e traces:

```bash
docker compose exec sampleapp bash /app/load.sh
```

Isso fará com que:
- O Prometheus colete novas métricas.
- O Loki receba logs.
- O Tempo registre novos traces.

---

## 🚨 Simulando Alertas

1. Localize a regra no arquivo `alert.rules.yml`.
2. Gere uma condição de alerta artificial (exemplo: aumentar uso de CPU).
3. Veja no Alertmanager: [http://localhost:9093](http://localhost:9093)

---

## 📈 Gerando Insights

- Use o **Grafana** para criar dashboards correlacionando métricas, logs e traces.
- Exemplo: Crie um painel com:
  - **Tempo de resposta médio** (Prometheus)
  - **Logs de erros** (Loki)
  - **Traces de requisições lentas** (Tempo)

---

## 📚 Guia de Estudos
Este repositório é ideal para aprender:
- Fundamentos de observabilidade.
- Criação de dashboards no Grafana.
- Consultas PromQL e LogQL.
- Configuração de alertas.
- Integração de métricas, logs e traces.

---

## 🛠 Próximos Passos
- Adicionar autenticação no Grafana e Prometheus.
- Criar alertas mais complexos.
- Integrar com Slack ou e-mail para notificações.
