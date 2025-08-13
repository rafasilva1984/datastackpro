#!/bin/bash

set -e

ZBX_API_URL="${ZBX_API_URL:-http://zabbix-web:8080/api_jsonrpc.php}"
ZBX_USER="${ZBX_USER:-Admin}"
ZBX_PASS="${ZBX_PASS:-zabbix}"

echo "⏳ Aguardando Zabbix Web ficar disponível..."
until curl -s -o /dev/null -w "%{http_code}" "$ZBX_API_URL" | grep -q "200"; do
  sleep 2
done

echo "✅ Zabbix Web está no ar!"

# Faz login e obtém o token de autenticação
LOGIN_PAYLOAD=$(cat <<EOF
{
  "jsonrpc": "2.0",
  "method": "user.login",
  "params": {
    "username": "$ZBX_USER",
    "password": "$ZBX_PASS"
  },
  "id": 1,
  "auth": null
}
EOF
)

RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d "$LOGIN_PAYLOAD" "$ZBX_API_URL")

ZBX_AUTH_TOKEN=$(echo "$RESPONSE" | grep -o '"result":"[^"]*' | cut -d':' -f2 | tr -d '"')

if [ -z "$ZBX_AUTH_TOKEN" ]; then
  echo "❌ Erro ao obter token de autenticação. Resposta completa:"
  echo "$RESPONSE"
  exit 1
fi

echo "🔑 Token obtido: $ZBX_AUTH_TOKEN"

# Exemplo: criação de grupo (pode ser removido ou ajustado conforme necessidade)
CREATE_GROUP_PAYLOAD=$(cat <<EOF
{
  "jsonrpc": "2.0",
  "method": "hostgroup.create",
  "params": {
    "name": "Grupo de Teste"
  },
  "auth": "$ZBX_AUTH_TOKEN",
  "id": 2
}
EOF
)

GROUP_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d "$CREATE_GROUP_PAYLOAD" "$ZBX_API_URL")

GROUP_ID=$(echo "$GROUP_RESPONSE" | grep -o '"groupids":\["[^"]*' | cut -d'"' -f3)

if [ -z "$GROUP_ID" ]; then
  echo "❌ Erro ao criar grupo. Resposta:"
  echo "$GROUP_RESPONSE"
  exit 1
fi

echo "📦 Grupo criado com ID: $GROUP_ID"

# Aqui você pode continuar com templates, hosts, etc.
