# ⚡ Elasticsearch Performance na Prática

Segundo repositório da trilha. Foco: performance, benchmark, diagnóstico e dashboards.

## Passo a passo
1. Suba o ambiente:
```bash
cd 01-ambiente-docker && docker-compose up -d
```
2. Crie índice e ingeste 10k docs:
```bash
cd ../02-benchmark-indexacao
bash criar-indice-base.sh
bash ingestar-bulk.sh
```
3. Rode benchmarks e compare:
```bash
bash benchmark-variacoes.sh
```
4. Diagnostique queries com profile:
```bash
cd ../04-diagnostico-queries
bash profile-examples.sh
```
5. Crie o dashboard (veja `05-dashboard-performance/instrucoes-dashboard.md`).

---

## 📊 Comparar tempos e impacto no cluster

Além dos scripts automáticos, você pode validar **manualmente** o efeito das configurações (refresh, réplicas, merges).  

### 1) Tempo de ingestão
- Os scripts já imprimem o tempo total de execução.  
- Rode mais de uma vez para o mesmo cenário e anote a média.

Exemplo:
```bash
# Cenário 1: padrão (refresh=1s, replicas=0)
bash criar-indice-base.sh
bash ingestar-bulk.sh

# Cenário 2: refresh=-1
bash criar-indice-base.sh
bash benchmark-variacoes.sh
```

| Cenário               | Tempo (s) |
|------------------------|-----------|
| refresh=1s, replicas=0 | 12        |
| refresh=-1             | 7         |
| replicas=1             | 14        |

---

### 2) Métricas do índice
Verifique docs, tamanho em disco e segmentos:

```bash
curl -s "http://localhost:9200/infra-hosts/_count?pretty"
curl -s "http://localhost:9200/_cat/indices?v"
curl -s "http://localhost:9200/infra-hosts/_stats?pretty" | head -n 100
```

**Dicas**:
- `docs.count`: deve sempre bater com 10000.  
- `store.size`: aumenta com mais réplicas.  
- `segments`: refresh=-1 reduz segmentação durante bulk.  

---

### 3) Latência de busca (profile)
Mede impacto em consultas:

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

Observe `rewrite_time`, `query_time`, `collector`.  
Teste logo após ingestão (com merges ativos) e depois de alguns segundos.

---

### 4) Réplicas e custo de escrita
```bash
# replicas=0
curl -X PUT "http://localhost:9200/infra-hosts/_settings"   -H 'Content-Type: application/json' -d '{"index":{"number_of_replicas":0}}'

bash ingestar-bulk.sh

# replicas=1
curl -X PUT "http://localhost:9200/infra-hosts/_settings"   -H 'Content-Type: application/json' -d '{"index":{"number_of_replicas":1}}'

bash ingestar-bulk.sh
```

Compare o tempo e veja se `store.size` aumentou.

---

### 5) Monitorando o nó
Valide saturação durante os testes:
```bash
curl -s "http://localhost:9200/_nodes/stats/thread_pool?pretty" | head -n 200
curl -s "http://localhost:9200/_nodes/stats/jvm,fs,process,os?pretty" | head -n 200
docker stats --no-stream
```

- `thread_pool.write.rejected` alto → gargalo de escrita  
- `heap_used_percent` alto → falta de memória  

---

### 6) Exemplo consolidado
| Cenário                         | Tempo (s) | Docs | Segments | Replicas | Refresh |
|---------------------------------|-----------|------|----------|----------|---------|
| Base (1s, replicas=0)            | 12        | 10000| 45       | 0        | 1s      |
| refresh=-1 (durante bulk)        | 7         | 10000| 12       | 0        | -1      |
| replicas=1 (após o bulk)         | 14        | 10000| 48       | 1        | 1s      |

**Conclusão (exemplo):**  
- `refresh=-1` → acelera ingestão (~40% mais rápido).  
- `replicas=1` → encarece escrita (~15–20% mais lenta).  
- Latência de busca tende a se estabilizar após merges.  

---

## Observações
- Se editar `.sh` no Windows e aparecer `^M`, use `dos2unix *.sh`.  
- Todos os dados usam timestamps de **julho/2025**.  
