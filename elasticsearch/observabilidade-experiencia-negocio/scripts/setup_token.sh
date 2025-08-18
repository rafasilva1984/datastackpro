#!/bin/bash
set -e

echo "🔑 Gerando Service Account Token para o Kibana..."

TOKEN=$(docker exec es-obs-exp-neg   bin/elasticsearch-service-tokens create elastic/kibana kb-token   | awk '/value/ {print $3}')

echo "KIBANA_SERVICE_ACCOUNT_TOKEN=$TOKEN" >> .env
echo "✅ Token salvo no .env"
