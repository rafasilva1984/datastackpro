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
└── README.md
```

## 🚀 Como usar

### 1. Suba o ambiente com Elastic 7.17

```bash
docker compose up -d
```

Acesse: [http://localhost:5601](http://localhost:5601)

### 2. Crie os templates de índice
```bash
curl -X PUT http://localhost:9200/_index_template/template-costs -H 'Content-Type: application/json' -d @ingest/templates/datastream_templates.json
```

### 3. Execute os scripts de ingestão
```bash
chmod +x simulate/*.sh
./simulate/ingest_costs.sh
./simulate/ingest_performance.sh
```

### 4. Importe os dashboards no Kibana
Acesse **Stack Management > Saved Objects > Import** e use os arquivos da pasta `dashboards/`.

## 📊 Métricas
- Latência média (ms)
- CPU usage (%)
- Total de erros
- Custo (R$)
- Relação custo/performance

## 🧠 Observação
Todos os dados são simulados com timestamps entre 01 e 05 de agosto de 2025.

---
**Autor:** [Rafael Silva](https://github.com/rafasilva1984) · Projeto DataStackPro