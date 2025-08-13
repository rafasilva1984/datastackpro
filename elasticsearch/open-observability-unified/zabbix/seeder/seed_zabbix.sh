#!/bin/sh
set -e

echo "⏳ Aguardando Zabbix Web ficar disponível..."
until curl -s -o /dev/null "$ZBX_URL"; do
  sleep 5
done
echo "✅ Zabbix Web está no ar!"

# Autenticação e obtenção de token
AUTH_TOKEN=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d @- "$ZBX_URL" <<EOF | jq -r '.result'
{
  "jsonrpc": "2.0",
  "method": "user.login",
  "params": {
    "user": "${ZBX_USER}",
    "password": "${ZBX_PASS}"
  },
  "id": 1
}
EOF
)

if [ -z "$AUTH_TOKEN" ] || [ "$AUTH_TOKEN" = "null" ]; then
  echo "❌ Erro ao obter token de autenticação. Verifique usuário e senha."
  exit 1
fi

echo "🔑 Token obtido: $AUTH_TOKEN"

# Criar grupo se não existir
GROUP_ID=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d @- "$ZBX_URL" <<EOF | jq -r '.result[0].groupid'
{
  "jsonrpc": "2.0",
  "method": "hostgroup.get",
  "params": {
    "filter": { "name": "$ZBX_GROUP" }
  },
  "auth": "$AUTH_TOKEN",
  "id": 1
}
EOF
)

if [ "$GROUP_ID" = "null" ] || [ -z "$GROUP_ID" ]; then
  GROUP_ID=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d @- "$ZBX_URL" <<EOF | jq -r '.result.groupids[0]'
{
  "jsonrpc": "2.0",
  "method": "hostgroup.create",
  "params": { "name": "$ZBX_GROUP" },
  "auth": "$AUTH_TOKEN",
  "id": 1
}
EOF
  )
  echo "📦 Grupo criado: $GROUP_ID"
else
  echo "📦 Grupo já existe: $GROUP_ID"
fi

# Obter template
TEMPLATE_ID=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d @- "$ZBX_URL" <<EOF | jq -r '.result[0].templateid'
{
  "jsonrpc": "2.0",
  "method": "template.get",
  "params": {
    "filter": { "host": "$ZBX_TEMPLATE" }
  },
  "auth": "$AUTH_TOKEN",
  "id": 1
}
EOF
)

echo "📋 Template encontrado: $TEMPLATE_ID"

# Criar hosts e item custom.trapper.random
IFS=',' read -ra HOSTS <<< "$ZBX_HOSTS"
for HOST in "${HOSTS[@]}"; do
  HOST_ID=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d @- "$ZBX_URL" <<EOF | jq -r '.result[0].hostid'
{
  "jsonrpc": "2.0",
  "method": "host.get",
  "params": {
    "filter": { "host": "$HOST" }
  },
  "auth": "$AUTH_TOKEN",
  "id": 1
}
EOF
  )

  if [ "$HOST_ID" = "null" ] || [ -z "$HOST_ID" ]; then
    HOST_ID=$(curl -s -X POST -H 'Content-Type: application/json' \
      -d @- "$ZBX_URL" <<EOF | jq -r '.result.hostids[0]'
{
  "jsonrpc": "2.0",
  "method": "host.create",
  "params": {
    "host": "$HOST",
    "interfaces": [{
      "type": 1,
      "main": 1,
      "useip": 1,
      "ip": "$HOST",
      "dns": "",
      "port": "10050"
    }],
    "groups": [{ "groupid": "$GROUP_ID" }],
    "templates": [{ "templateid": "$TEMPLATE_ID" }]
  },
  "auth": "$AUTH_TOKEN",
  "id": 1
}
EOF
    )
    echo "🖥 Host criado: $HOST_ID ($HOST)"
  else
    echo "🖥 Host já existe: $HOST_ID ($HOST)"
  fi

  # Criar item trapper custom.trapper.random
  ITEM_ID=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d @- "$ZBX_URL" <<EOF | jq -r '.result[0].itemid'
{
  "jsonrpc": "2.0",
  "method": "item.get",
  "params": {
    "hostids": "$HOST_ID",
    "filter": { "key_": "custom.trapper.random" }
  },
  "auth": "$AUTH_TOKEN",
  "id": 1
}
EOF
  )

  if [ "$ITEM_ID" = "null" ] || [ -z "$ITEM_ID" ]; then
    ITEM_ID=$(curl -s -X POST -H 'Content-Type: application/json' \
      -d @- "$ZBX_URL" <<EOF | jq -r '.result.itemids[0]'
{
  "jsonrpc": "2.0",
  "method": "item.create",
  "params": {
    "name": "Custom Random Value",
    "key_": "custom.trapper.random",
    "hostid": "$HOST_ID",
    "type": 2,
    "value_type": 3,
    "delay": "0"
  },
  "auth": "$AUTH_TOKEN",
  "id": 1
}
EOF
    )
    echo "📊 Item criado: $ITEM_ID"
  else
    echo "📊 Item já existe: $ITEM_ID"
  fi
done

echo "✅ Seeder concluído!"
