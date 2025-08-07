#!/bin/bash

echo "Iniciando ingestão de custos..."

for cluster in $(cat simulate/clusters.txt); do
  for service in $(cat simulate/services.txt); do
    custo=$(( (RANDOM % 1000) + 100 ))
    timestamp=$(date -d "2025-08-0$(( (RANDOM % 5) + 1 ))" +"%Y-%m-%dT%H:%M:%S")

    curl -s -X POST "http://localhost:9200/log-cost/_doc" -H 'Content-Type: application/json' -d "{
      \"cluster\": \"$cluster\",
      \"service\": \"$service\",
      \"cost\": $custo,
      \"timestamp\": \"$timestamp\"
    }"
  done
done

echo "Ingestão de custos finalizada."
