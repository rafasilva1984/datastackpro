# Observabilidade com FinOps: Painel de Custo e Performance por Serviço com Elasticsearch

Este projeto demonstra como correlacionar **custos operacionais** e **performance técnica** de serviços em ambientes observáveis, utilizando o Elastic Stack. Ideal para times de SRE, FinOps e gestores técnicos.

## 📦 Estrutura
```
.
├── simulate/                   # Scripts bash para simular ingestão de dados
│   ├── ingest_costs.sh
│   ├── ingest_performance.sh
│   ├── clusters.txt
│   └── services.txt
├── ingest/
│   ├── mappings/
│   │   ├── cost_index.json
│   │   └── perf_index.json
│   └── templates/
│       └── datastream_templates.json
├── dashboards/
│   ├── painel-geral.ndjson
│   ├── painel-clusters.ndjson
│   ├── painel-servico.ndjson
│   └── painel-anomalias.ndjson
├── docker-compose.yml          # Stack Elasticsearch + Kibana sem autenticação
├── kibana.yml                  # Config Kibana para permitir acesso externo
└── README.md
```

---

## 🚀 Como usar

### 1. Suba o ambiente com Elasticsearch + Kibana (sem autenticação)

```bash
docker compose up -d
```

> O `docker-compose.yml` já está configurado para **não exigir autenticação** e o Kibana escutar em `0.0.0.0`.

Acesse:
- Elasticsearch: http://localhost:9200
- Kibana: http://localhost:5601

---

### 2. Crie os templates de índice
```bash
curl -X PUT http://localhost:9200/_index_template/template-costs \
  -H 'Content-Type: application/json' \
  -d @ingest/templates/datastream_templates.json
```

---

### 3. Execute os scripts de ingestão simulada
```bash
chmod +x simulate/*.sh
./simulate/ingest_costs.sh
./simulate/ingest_performance.sh
```

---

### 4. Importe os dashboards no Kibana
1. Vá até **Stack Management > Saved Objects > Import**
2. Selecione os arquivos `.ndjson` da pasta `dashboards/`

---

### 5. Visualize e filtre por:
- Serviço
- Cluster
- Data
- Erros
- Custo (R$)
- Relação custo/performance

---

## 📊 Métricas monitoradas

- Latência média (ms)
- CPU usage (%)
- Total de erros
- Custo em reais (R$)
- Custo/performance (insight visual)

---

## 🧠 Observação

- Todos os dados são simulados com timestamps entre **01 e 05 de agosto de 2025**
- Ideal para demonstração de valor em projetos de Observabilidade + FinOps
- Pode ser adaptado facilmente para ambientes com autenticação e produção

---

**Autor:** [Rafael Silva](https://github.com/rafasilva1984) · Projeto [DataStackPro](https://github.com/rafasilva1984/datastackpro)
