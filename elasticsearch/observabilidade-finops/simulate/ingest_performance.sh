#!/bin/bash
echo "Iniciando ingestão de performance..."

for cluster in $(cat simulate/clusters.txt); do
  for service in $(cat simulate/services.txt); do
    for day in $(seq -w 1 5); do
      curl -s -X POST "http://localhost:9200/perf-datastream/_doc" \
      -H 'Content-Type: application/json' \
      -u elastic:changeme \
      -d '{
        "@timestamp": "2025-08-'$day'T12:00:00Z",
        "cluster_uuid": "'$cluster'",
        "servico": "'$service'",
        "latencia_ms": '$(shuf -i 50-300 -n 1)',
        "cpu_percent": '$(shuf -i 10-90 -n 1)',
        "erros_total": '$(shuf -i 0-15 -n 1)'
      }' > /dev/null
    done
  done
done

echo "Ingestão de performance finalizada."
