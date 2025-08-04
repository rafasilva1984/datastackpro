#!/bin/bash
curl -X POST "localhost:9200/infra-logs/_bulk" \
  -H 'Content-Type: application/json' \
  --data-binary @ingestao/dados-infra.json
