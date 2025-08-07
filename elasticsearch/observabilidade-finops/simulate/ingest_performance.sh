#!/bin/bash

echo "Iniciando ingestão de performance..."

for cluster in $(tr -d '\r' < simulate/clusters.txt); do
  for service in $(tr -d '\r' < simulate/services.txt); do
    latency=$(( (RANDOM % 1000) + 100 ))
    cpu=$(( (RANDOM % 100) + 1 ))
    errors=$(( (RANDOM % 5) ))
    timestamp=$(date -d "2025-08-0$(( (RANDOM % 5) + 1 ))" +"%Y-%m-%dT%H:%M:%S")

    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://localhost:9200/log-perf/_doc" -H 'Content-Type: application/json' -d "{
      \"cluster\": \"$cluster\",
      \"service\": \"$service\",
      \"latency\": $latency,
      \"cpu\": $cpu,
      \"errors\": $errors,
      \"timestamp\": \"$timestamp\"
    }")

    if [[ "$response" != "201" ]]; then
      echo "❌ Erro ao inserir doc: $cluster/$service ($response)"
    fi
  done
done

echo "Ingestão de performance finalizada."
