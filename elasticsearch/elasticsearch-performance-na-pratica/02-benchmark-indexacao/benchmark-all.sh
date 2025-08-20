#!/usr/bin/env bash
# benchmark-all.sh — compara efeitos de refresh_interval e replicas na ingestão
# Requisitos: curl; (opcional) jq para métricas mais legíveis

set -euo pipefail

ES_URL="${ES_URL:-http://localhost:9200}"
INDEX="${INDEX:-infra-hosts}"
FILE="${FILE:-dados-10000.ndjson}"

# --- helpers ---------------------------------------------------------------

hr() { printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' -; }

wait_green() {
  # aguarda ES responder green/yellow/green
  for i in {1..60}; do
    if curl -fsS "$ES_URL/_cluster/health?pretty" >/dev/null; then return 0; fi
    sleep 1
  done
  echo "⚠️  ES não respondeu a tempo em $ES_URL"; exit 1
}

recreate_index() {
  curl -fsS -X DELETE "$ES_URL/$INDEX" >/dev/null || true
  curl -fsS -X PUT "$ES_URL/$INDEX" -H 'Content-Type: application/json' -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "refresh_interval": "1s"
    },
    "mappings": {
      "properties": {
        "host":      { "type": "keyword" },
        "servico":   { "type": "keyword" },
        "status":    { "type": "keyword" },
        "cpu":       { "type": "integer" },
        "memoria":   { "type": "integer" },
        "@timestamp":{ "type": "date" }
      }
    }
  }' >/dev/null
}

bulk_ingest() {
  local ndjson="$1"
  local start end
  start=$(date +%s)
  curl -fsS -H 'Content-Type: application/x-ndjson' -X POST "$ES_URL/_bulk" --data-binary "@${ndjson}" >/dev/null
  curl -fsS -X POST "$ES_URL/$INDEX/_refresh" >/dev/null
  end=$(date +%s)
  echo $((end - start))
}

docs_count() {
  curl -fsS "$ES_URL/$INDEX/_count" | grep -o '"count":[0-9]*' | cut -d: -f2
}

store_size_mb() {
  # pega size em MB do _cat/indices
  curl -fsS "$ES_URL/_cat/indices/$INDEX?bytes=mb" | awk '{print $(NF-1)}'
}

profile_latency_ms() {
  # mede latência de uma query típica (warning + cpu>=85)
  # retorna soma aproximada de query_time dos shards (ms)
  local resp
  resp=$(curl -fsS -H 'Content-Type: application/json' -X POST "$ES_URL/$INDEX/_search" -d '{
    "size": 0,
    "profile": true,
    "query": {
      "bool": {
        "must": [
          { "match": { "status": "warning" } },
          { "range": { "cpu": { "gte": 85 } } }
        ]
      }
    }
  }')
  # extrai números (sem jq), soma básica
  echo "$resp" | tr ',{}[]' '\n' | grep -E '"time_in_nanos":[0-9]+' \
    | sed 's/[^0-9]//g' | awk '{sum+=$1} END{printf("%.2f", sum/1000000)}'
}

print_row() {
  # columns: Cenário | Tempo(s) | Docs | Store(MB) | Profile(ms)
  printf "%-28s | %9s | %8s | %9s | %11s\n" "$1" "$2" "$3" "$4" "$5"
}

# --- prechecks -------------------------------------------------------------

if [[ ! -f "$FILE" ]]; then
  echo "❌ Arquivo NDJSON não encontrado: $FILE"
  echo "   Esperado em 02-benchmark-indexacao/$FILE"
  exit 1
fi

echo "ES_URL=$ES_URL  INDEX=$INDEX  FILE=$FILE"
wait_green
hr

# --- CENÁRIO 1: Base (refresh=1s, replicas=0) ------------------------------

echo "🔵 Cenário 1: Base (refresh=1s, replicas=0)"
recreate_index
t1=$(bulk_ingest "$FILE")
c1=$(docs_count)
s1=$(store_size_mb)
p1=$(profile_latency_ms)
print_row "Base (1s, replicas=0)" "$t1" "$c1" "$s1" "$p1"
hr

# --- CENÁRIO 2: refresh=-1 durante o bulk ---------------------------------

echo "🟠 Cenário 2: refresh=-1 (durante o bulk)"
recreate_index
curl -fsS -X PUT "$ES_URL/$INDEX/_settings" -H 'Content-Type: application/json' -d '{"index":{"refresh_interval":"-1"}}' >/dev/null
t2=$(bulk_ingest "$FILE")  # bulk com refresh desligado
# reativar
curl -fsS -X PUT "$ES_URL/$INDEX/_settings" -H 'Content-Type: application/json' -d '{"index":{"refresh_interval":"1s"}}' >/dev/null
c2=$(docs_count)
s2=$(store_size_mb)
p2=$(profile_latency_ms)
print_row "Bulk c/ refresh=-1" "$t2" "$c2" "$s2" "$p2"
hr

# --- CENÁRIO 3: replicas=1 após ingestão ----------------------------------

echo "🟣 Cenário 3: replicas=1 (após ingestão)"
recreate_index
t3=$(bulk_ingest "$FILE")
curl -fsS -X PUT "$ES_URL/$INDEX/_settings" -H 'Content-Type: application/json' -d '{"index":{"number_of_replicas":1}}' >/dev/null
# espera estabilizar réplicas
sleep 3
c3=$(docs_count)
s3=$(store_size_mb)
p3=$(profile_latency_ms)
print_row "Replicas=1 (pós-bulk)" "$t3" "$c3" "$s3" "$p3"
hr

# --- RESUMO ---------------------------------------------------------------

echo "✅ RESUMO (menor tempo = melhor para ingestão)"
printf "%-28s | %9s | %8s | %9s | %11s\n" "Cenário" "Tempo(s)" "Docs" "Store(MB)" "Profile(ms)"
hr
print_row "Base (1s, replicas=0)" "$t1" "$c1" "$s1" "$p1"
print_row "Bulk c/ refresh=-1"   "$t2" "$c2" "$s2" "$p2"
print_row "Replicas=1 (pós-bulk)" "$t3" "$c3" "$s3" "$p3"
hr

echo "💡 Interpretação:"
echo "- refresh=-1 costuma REDUZIR o tempo de ingestão (menos refresh/segmentos durante o bulk)."
echo "- replicas=1 tende a AUMENTAR custo de escrita; útil para leitura/HA, mas mais lento para ingestão."
echo "- Profile(ms) dá uma noção da soma de tempos de busca por shard (aprox.). Faça 2–3 rodadas e compare médias."
