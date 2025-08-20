#!/bin/bash
set -e
echo "== Profile: status=warning AND cpu>=85 =="
curl -s -H 'Content-Type: application/json' -X POST "http://localhost:9200/infra-hosts/_search?pretty" -d '{
  "profile": true,
  "query": {
    "bool": {
      "must": [
        { "match": { "status": "warning" } },
        { "range": { "cpu": { "gte": 85 } } }
      ]
    }
  }
}'
