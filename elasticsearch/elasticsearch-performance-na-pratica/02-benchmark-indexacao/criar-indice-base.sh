#!/bin/bash
set -e
INDEX="infra-hosts"
curl -s -X DELETE "http://localhost:9200/$INDEX" >/dev/null || true
curl -s -X PUT "http://localhost:9200/$INDEX" -H 'Content-Type: application/json' -d '{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0,
    "refresh_interval": "1s"
  },
  "mappings": {
    "properties": {
      "host":     { "type": "keyword" },
      "servico":  { "type": "keyword" },
      "status":   { "type": "keyword" },
      "cpu":      { "type": "integer" },
      "memoria":  { "type": "integer" },
      "@timestamp": { "type": "date" }
    }
  }
}' && echo -e "\nÍndice $INDEX criado."
