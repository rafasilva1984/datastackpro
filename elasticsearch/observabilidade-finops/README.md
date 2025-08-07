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

### 1. Suba o Elastic Stack (mínimo v7.17)

Pode usar `docker-compose` com Elasticsearch e Kibana habilitados com autenticação básica (`elastic/changeme`).

### 2. Crie os templates de índice
```bash
curl -u elastic:changeme -X PUT http://localhost:9200/_index_template/template-costs -H 'Content-Type: application/json' -d @ingest/templates/datastream_templates.json
```

### 3. Execute os scripts de ingestão
```bash
chmod +x simulate/*.sh
./simulate/ingest_costs.sh
./simulate/ingest_performance.sh
```

### 4. Importe os dashboards no Kibana
Acesse **Stack Management > Saved Objects > Import** e use os arquivos da pasta `dashboards/`.

### 5. Visualize e filtre por:
- Serviço
- Cluster
- Data
- Erro
- Custo

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


---

## 🐳 Como subir o ambiente com autenticação via token (Elasticsearch 8.x+)

Atenção: o Kibana **não permite mais autenticação direta com o usuário `elastic`**.

### ✅ Passo a passo completo:

```bash
# 1. Suba apenas o Elasticsearch
docker compose up -d elasticsearch

# 2. Gere o token de serviço para o Kibana
./create_kibana_token.sh
```

O script vai retornar algo como:

```
elastic/kibana/kibana-token: AAEAAWVsYXN0aWMva2liYW5hL2tpYmFuYS10b2tlbjpKRkRCQ1dI...
```

### 3. Copie o token e substitua no arquivo `docker-compose.yml`, na parte do Kibana:
```yaml
environment:
  - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
  - ELASTICSEARCH_SERVICE_ACCOUNT_TOKEN=AAEAAWVsYXN0aWMva2liYW5h... (cole aqui)
```

💡 Remova ou comente as linhas abaixo, se estiverem presentes:
```yaml
# - ELASTICSEARCH_USERNAME=elastic
# - ELASTICSEARCH_PASSWORD=changeme
```

### 4. Suba o Kibana
```bash
docker compose up -d kibana
```

O Kibana agora irá autenticar corretamente usando o token gerado.
