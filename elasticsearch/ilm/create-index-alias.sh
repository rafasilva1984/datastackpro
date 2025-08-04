#!/bin/bash

# Cria a política ILM
curl -X PUT "http://localhost:9200/_ilm/policy/infra-ilm-policy" \
  -H 'Content-Type: application/json' \
  -d @ilm/ilm-policy.json

# Aplica o template de índice com suporte a data stream
curl -X PUT "http://localhost:9200/_index_template/infra-template" \
  -H 'Content-Type: application/json' \
  -d @ilm/index-template.json

# Cria o data stream (infra-logs) com base no template
curl -X PUT "http://localhost:9200/_data_stream/infra-logs"
