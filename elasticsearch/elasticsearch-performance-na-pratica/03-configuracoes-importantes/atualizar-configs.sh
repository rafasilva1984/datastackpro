#!/bin/bash
set -e
INDEX="infra-hosts"
echo "Aumentando refresh_interval para 5s..."
curl -s -X PUT "http://localhost:9200/$INDEX/_settings" -H 'Content-Type: application/json' -d '{
  "index": { "refresh_interval": "5s" }
}'
echo
echo "Definindo number_of_replicas = 0..."
curl -s -X PUT "http://localhost:9200/$INDEX/_settings" -H 'Content-Type: application/json' -d '{
  "index": { "number_of_replicas": 0 }
}'
echo
