#!/bin/sh
echo "🔁 Gerando carga automática para a sampleapp..."
sleep 5
i=0
while true; do
  i=$((i+1))
  curl -s sampleapp:3000/login > /dev/null
  curl -s sampleapp:3000/checkout > /dev/null
  # 15% de erros
  if [ $((i % 7)) -eq 0 ]; then
    curl -s sampleapp:3000/error > /dev/null
  fi
  sleep 0.5
done
