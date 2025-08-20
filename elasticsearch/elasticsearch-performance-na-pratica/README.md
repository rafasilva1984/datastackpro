# ⚡ Elasticsearch Performance na Prática

Segundo repositório da trilha. Foco: performance, benchmark, diagnóstico e dashboards.

## Passo a passo
1. **Suba o ambiente**:
```bash
cd 01-ambiente-docker && docker-compose up -d
```
2. **Crie índice e ingeste 10k docs**:
```bash
cd ../02-benchmark-indexacao
bash criar-indice-base.sh
bash ingestar-bulk.sh
```
3. **Rode benchmarks e compare**  
Você pode seguir de duas formas:
- **Manual**: `bash benchmark-variacoes.sh` (executa cenários guiados)
- **Automática**: **`bash benchmark-all.sh`** (tudo de uma vez com tabela-resumo)

4. **Diagnostique queries com profile**:
```bash
cd ../04-diagnostico-queries
bash profile-examples.sh
```
➡️ Leia também `04-diagnostico-queries/profile-cheatsheet.md` e use os exemplos em `diagnostico-demos.json`.

5. **Crie o dashboard** (veja `05-dashboard-performance/instrucoes-dashboard.md`).

---

## 📊 Comparar tempos e impacto no cluster

### 1) Tempo de ingestão (método manual)
```bash
# Cenário 1: padrão (refresh=1s, replicas=0)
bash criar-indice-base.sh
bash ingestar-bulk.sh

# Cenário 2: refresh=-1 (mede ingestão com refresh desligado)
bash criar-indice-base.sh
bash benchmark-variacoes.sh
```

| Cenário               | Tempo (s) |
|------------------------|-----------|
| refresh=1s, replicas=0 | 12        |
| refresh=-1             | 7         |
| replicas=1             | 14        |

### 2) Métricas do índice
```bash
curl -s "http://localhost:9200/infra-hosts/_count?pretty"
curl -s "http://localhost:9200/_cat/indices?v"
curl -s "http://localhost:9200/infra-hosts/_stats?pretty" | head -n 100
```

### 3) Latência de busca (profile)
```bash
curl -s -H 'Content-Type: application/json'   -X POST "http://localhost:9200/infra-hosts/_search?pretty" -d '{
    "profile": true,
    "size": 0,
    "query": {
      "bool": {
        "must": [
          { "match": { "status": "warning" } },
          { "range": { "cpu": { "gte": 85 } } }
        ]
      }
    }
  }'
```
Teste logo após ingestão (com merges ativos) e depois de alguns segundos.

### 4) Réplicas e custo de escrita
```bash
curl -X PUT "http://localhost:9200/infra-hosts/_settings"   -H 'Content-Type: application/json' -d '{"index":{"number_of_replicas":0}}'
bash ingestar-bulk.sh

curl -X PUT "http://localhost:9200/infra-hosts/_settings"   -H 'Content-Type: application/json' -d '{"index":{"number_of_replicas":1}}'
bash ingestar-bulk.sh
```

### 5) Monitorando o nó
```bash
curl -s "http://localhost:9200/_nodes/stats/thread_pool?pretty" | head -n 200
curl -s "http://localhost:9200/_nodes/stats/jvm,fs,process,os?pretty" | head -n 200
docker stats --no-stream
```

### 6) Exemplo consolidado
| Cenário                         | Tempo (s) | Docs | Segments | Replicas | Refresh |
|---------------------------------|-----------|------|----------|----------|---------|
| Base (1s, replicas=0)            | 12        | 10000| 45       | 0        | 1s      |
| refresh=-1 (durante bulk)        | 7         | 10000| 12       | 0        | -1      |
| replicas=1 (após o bulk)         | 14        | 10000| 48       | 1        | 1s      |

---

## ⚙️ Execução automática (benchmark-all.sh)

Automatize tudo e obtenha um **resumo consolidado**:
```bash
cd 02-benchmark-indexacao
chmod +x benchmark-all.sh
./benchmark-all.sh
```

Variáveis opcionais:
```bash
ES_URL=http://localhost:9200 INDEX=infra-perf FILE=dados-10000.ndjson ./benchmark-all.sh
```

---

## 🔎 Diagnóstico com _search/profile_ — guia prático

O `profile` é o **raio-X da busca**. Com `"profile": true` você vê **onde o tempo é gasto** (por shard e por operação).

### Principais métricas
- **rewrite_time** → custo para reescrever a query (wildcards, regex, expansions).  
- **query[].time_in_nanos** → tempo de execução da query em si.  
- **collector** → custo para ordenar/coletar resultados (`size` alto ou `sort` complexos aumentam).  
- **breakdown** → detalhamento de cada etapa interna (peso, iteração, pontuação).  
- **aggs** → tempo consumido pelas agregações.

---

### Demos disponíveis
Você pode rodar direto no Kibana Dev Tools ou via cURL (`profile-examples.sh`):

1. **Baseline** — `status=warning AND cpu>=85` (mede custo de `match` + `range`).  
2. **Otimização** — `term` em `status.keyword` + `range` em `cpu`.  
3. **Com agregação** — `terms` por `servico` para medir custo de agregações.  
4. **Ordenação** — ordenar por `@timestamp desc` para observar impacto no `collector`.

👉 Todos esses exemplos estão em:  
- `04-diagnostico-queries/diagnostico-demos.json` (pacote de queries prontas).  
- `04-diagnostico-queries/queries-exemplos.json` (modelos de uso).  

---

### Checklist de interpretação
- Query lenta em campo `text`? Use `keyword` com `term`.  
- Custo alto no `collector`? Reduza `size`, aplique filtros antes ou use `search_after`.  
- Agregação pesada? Restrinja o conjunto de dados antes (`filter + aggs`).  
- Um shard sempre mais lento? Reindex, ajuste de shard size ou forcemerge (somente laboratório).  

---

## Observações
- Se editar `.sh` no Windows e aparecer `^M`, use `dos2unix *.sh`.  
- Todos os dados usam timestamps de **julho/2025**.  
