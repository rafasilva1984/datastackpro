#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$ROOT_DIR/.env" ]; then
  # shellcheck disable=SC1091
  source "$ROOT_DIR/.env"
else
  echo "Arquivo .env não encontrado. Copie de .env.example" >&2
  exit 1
fi

ES="${STACK_HOST:-http://localhost:9200}"
AUTH="elastic:${ELASTIC_PASSWORD}"

echo "➡️ Removendo data streams e templates (se existirem)..."
curl -s -u "$AUTH" -X DELETE "$ES/_data_stream/app-logs-default" || true
curl -s -u "$AUTH" -X DELETE "$ES/_data_stream/biz-metrics-default" || true

curl -s -u "$AUTH" -X DELETE "$ES/_ilm/policy/app-logs-ilm" || true
curl -s -u "$AUTH" -H 'Content-Type: application/json' -X DELETE "$ES/_index_template/app-logs-template" || true
curl -s -u "$AUTH" -H 'Content-Type: application/json' -X DELETE "$ES/_index_template/biz-metrics-template" || true

echo "✅ Reset concluído."
