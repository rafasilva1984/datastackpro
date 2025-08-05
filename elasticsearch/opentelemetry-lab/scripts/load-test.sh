
#!/bin/bash

echo "🔁 Gerando carga automática para aplicação..."
for i in {1..70}; do
  curl -s http://localhost:3000/login > /dev/null
  curl -s http://localhost:3000/checkout > /dev/null
  curl -s http://localhost:3000/error > /dev/null || true
done
echo "✅ Carga gerada com sucesso. Verifique os dados no Kibana!"
