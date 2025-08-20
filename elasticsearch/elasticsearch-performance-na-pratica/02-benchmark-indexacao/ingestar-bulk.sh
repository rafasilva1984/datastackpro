#!/bin/bash
set -e
INDEX="infra-hosts"
FILE="dados-10000.ndjson"
echo "Ingestando 10.000 documentos em $INDEX ..."
START=$(date +%s)
curl -s -H 'Content-Type: application/x-ndjson' -X POST "http://localhost:9200/_bulk" --data-binary "@$FILE" >/dev/null
END=$(date +%s)
echo "Concluído em $((END-START))s"
echo "Forçando refresh..."
curl -s -X POST "http://localhost:9200/$INDEX/_refresh" >/dev/null && echo "OK"
echo "Total de docs:"
curl -s "http://localhost:9200/$INDEX/_count?pretty"
