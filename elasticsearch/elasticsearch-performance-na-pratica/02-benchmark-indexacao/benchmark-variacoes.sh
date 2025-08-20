#!/bin/bash
set -e
INDEX="infra-hosts"

echo "==> Cenário A: refresh_interval = -1 durante o bulk"
curl -s -X PUT "http://localhost:9200/$INDEX/_settings" -H 'Content-Type: application/json' -d '{
  "index": { "refresh_interval": "-1" }
}' >/dev/null

echo "   Ingestão com refresh desligado (reindex do arquivo NDJSON) ..."
START=$(date +%s)
curl -s -H 'Content-Type: application/x-ndjson' -X POST "http://localhost:9200/_bulk" --data-binary "@dados-10000.ndjson" >/dev/null
END=$(date +%s)
echo "   Tempo (s): $((END-START))"

echo "==> Reativando refresh = 1s"
curl -s -X PUT "http://localhost:9200/$INDEX/_settings" -H 'Content-Type: application/json' -d '{
  "index": { "refresh_interval": "1s" }
}' >/dev/null

echo "==> Cenário B: replicas = 0 vs 1"
echo "   Ajustando replicas = 0 ..."
curl -s -X PUT "http://localhost:9200/$INDEX/_settings" -H 'Content-Type: application/json' -d '{
  "index": { "number_of_replicas": 0 }
}' >/dev/null

sleep 2
echo "   Ajustando replicas = 1 ..."
curl -s -X PUT "http://localhost:9200/$INDEX/_settings" -H 'Content-Type: application/json' -d '{
  "index": { "number_of_replicas": 1 }
}' >/dev/null
echo "Pronto. Compare tempos e impacto no cluster."
