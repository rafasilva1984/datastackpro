#!/bin/bash

echo "🔁 Gerando carga automática para a SampleApp..."

for i in {1..1000}; do
  curl -s http://localhost:3001/login    > /dev/null
  curl -s http://localhost:3001/checkout > /dev/null
  curl -s http://localhost:3001/error    > /dev/null || true
done

echo "✅ Carga gerada com sucesso! Verifique os dashboards no Grafana e Kibana."
