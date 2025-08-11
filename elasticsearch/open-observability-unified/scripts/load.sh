#!/bin/bash
set -euo pipefail
echo "🔁 Gerando carga automática para a aplicação..."
SLEEP_SECONDS="${SLEEP_SECONDS:-1}"

while true; do
  curl -s http://sampleapp:3000/login > /dev/null || true
  curl -s http://sampleapp:3000/checkout > /dev/null || true
  # gera alguns erros de propósito
  curl -s http://sampleapp:3000/error > /dev/null || true
  sleep "$SLEEP_SECONDS"
done
