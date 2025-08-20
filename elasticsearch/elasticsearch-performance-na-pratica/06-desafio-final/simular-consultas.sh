#!/bin/bash
echo "Hosts críticos (CPU>=85 OR Mem>=90)"
curl -s -H 'Content-Type: application/json' -X POST "http://localhost:9200/infra-hosts/_search?pretty" -d '{
  "query": {
    "bool": {
      "should": [
        { "range": { "cpu": { "gte": 85 } } },
        { "range": { "memoria": { "gte": 90 } } }
      ]
    }
  },
  "sort": [{"@timestamp":"desc"}],
  "size": 10
}'
