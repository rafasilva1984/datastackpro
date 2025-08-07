#!/bin/bash
echo "Iniciando ingestão de custos..."

for cluster in $(cat simulate/clusters.txt); do
  for service in $(cat simulate/services.txt); do
    for day in $(seq -w 1 5); do
      curl -s -X POST "http://localhost:9200/cost-datastream/_doc" \
      -H 'Content-Type: application/json' \
      -u elastic:changeme \
      -d '{
        "@timestamp": "2025-08-'$day'T12:00:00Z",
        "cluster_uuid": "'$cluster'",
        "servico": "'$service'",
        "custo_reais": '$(shuf -i 50-500 -n 1)
      }' > /dev/null
    done
  done
done

echo "Ingestão de custos finalizada."
