#!/bin/bash
curl -X PUT "localhost:9200/_ilm/policy/infra-ilm-policy" \
  -H 'Content-Type: application/json' \
  -d @ilm/ilm-policy.json

curl -X PUT "localhost:9200/_index_template/infra-template" \
  -H 'Content-Type: application/json' \
  -d @ilm/index-template.json

curl -X POST "localhost:9200/infra-logs-000001" \
  -H 'Content-Type: application/json' \
  -d '{ "aliases": { "infra-logs": { "is_write_index": true } } }'
