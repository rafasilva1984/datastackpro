#!/bin/bash
set -e

echo "👤 Criando usuário ds_admin..."

docker exec es-obs-exp-neg curl -s -u elastic:$ELASTIC_PASSWORD -X POST "localhost:9200/_security/user/ds_admin" -H 'Content-Type: application/json' -d '{
  "password": "ds_admin123",
  "roles": ["superuser"],
  "full_name": "DataStackPro Admin"
}'

echo "✅ Usuário ds_admin criado com senha ds_admin123"
