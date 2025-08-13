#!/bin/sh
set -e

echo "⏳ Aguardando Zabbix Web ficar disponível..."
until curl -s -o /dev/null "$ZBX_URL"; do
  sleep 5
done
echo "✅ Zabbix Web está no ar!"

# Login e pegar token
AUTH_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d @- "$ZBX_URL" <<EOF
{
  "jsonrpc": "2.0",
  "method": "user.login",
  "params": {
    "user": "$ZBX_USER",
    "password": "$ZBX_PASS"
  },
  "id": 1
}
EOF
)

AUTH_TOKEN=$(echo "$AUTH_RESPONSE" | sed -n 's/.*"result":"\([^"]*\)".*/\1/p')

if [ -z "$AUTH_TOKEN" ]; then
  echo "❌ Erro ao obter token de autenticação. Resposta completa:"
  echo "$AUTH_RESPONSE"
  exit 1
else
  echo "🔑 Token obtido com sucesso!"
fi

# Criar grupo se não existir
GROUP_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d @- "$ZBX_URL" <<EOF
{
  "jsonrpc": "2.0",
  "method": "hostgroup.get",
  "params": { "filter": { "name": "$ZBX_GROUP" } },
  "auth": "$AUTH_TOKEN",
  "id": 1
}
EOF
)

GROUP_ID=$(echo "$GROUP_RESPONSE" | sed -n 's/.*"groupid":"\([^"]*\)".*/\1/p')

if [ -z "$GROUP_ID" ]; then
  CREATE_GROUP_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d @- "$ZBX_URL" <<EOF
{
  "jsonrpc": "2.0",
  "method": "hostgroup.create",
  "params": { "name": "$ZBX_GROUP" },
  "auth": "$AUTH_TOKEN",
  "id": 1
}
EOF
)
  GROUP_ID=$(echo "$CREATE_GROUP_RESPONSE" | sed -n 's/.*"groupids":\["\([^"]*\)"\].*/\1/p')
  echo "📦 Grupo criado: $GROUP_ID"
else
  echo "📦 Grupo já existe: $GROUP_ID"
fi

# Obter template
TEMPLATE_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d @- "$ZBX_URL" <<EOF
{
  "jsonrpc": "2.0",
  "method": "template.get",
  "params": { "filter": { "host": "$ZBX_TEMPLATE" } },
  "auth": "$AUTH_TOKEN",
  "id": 1
}
EOF
)

TEMPLATE_ID=$(echo "$TEMPLATE_RESPONSE" | sed -n 's/.*"templateid":"\([^"]*\)".*/\1/p')

if [ -z "$TEMPLATE_ID" ]; then
  echo "❌ Template \"$ZBX_TEMPLATE\" não encontrado!"
  exit 1
else
  echo "📋 Template encontrado: $TEMPLATE_ID"
fi

# Criar hosts e itens
IFS=',' read -ra HOSTS <<< "$ZBX_HOSTS"
for HOST in "${HOSTS[@]}"; do
  HOST_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d @- "$ZBX_URL" <<EOF
{
  "jsonrpc": "2.0",
  "method": "host.get",
  "params": { "filter": { "host": "$HOST" } },
  "auth": "$AUTH_TOKEN",
  "id": 1
}
EOF
)
  HOST_ID=$(echo "$HOST_RESPONSE" | sed -n 's/.*"hostid":"\([^"]*\)".*/\1/p')

  if [ -z "$HOST_ID" ]; then
    CREATE_HOST_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
      -d @- "$ZBX_URL" <<EOF
{
  "jsonrpc": "2.0",
  "method": "host.create",
  "params": {
    "host": "$HOST",
    "interfaces": [
      {
        "type": 1,
        "main": 1,
        "useip": 1,
        "ip": "$HOST",
        "dns": "",
        "port": "10050"
      }
    ],
    "groups": [{ "groupid": "$GROUP_ID" }],
    "templates": [{ "templateid": "$TEMPLATE_ID" }]
  },
  "auth": "$AUTH_TOKEN",
  "id": 1
}
EOF
)
    HOST_ID=$(echo "$CREATE_HOST_RESPONSE" | sed -n 's/.*"hostids":\["\([^"]*\)".*/\1/p')
    echo "🖥 Host criado: $HOST_ID ($HOST)"
  else
    echo "🖥 Host já existe: $HOST_ID ($HOST)"
  fi

  # Criar item trapper
  ITEM_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d @- "$ZBX_URL" <<EOF
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
  ITEM_ID=$(echo "$ITEM_RESPONSE" | sed -n 's/.*"itemid":"\([^"]*\)".*/\1/p')

  if [ -z "$ITEM_ID" ]; then
    CREATE_ITEM_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
      -d @- "$ZBX_URL" <<EOF
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
    ITEM_ID=$(echo "$CREATE_ITEM_RESPONSE" | sed -n 's/.*"itemids":\["\([^"]*\)".*/\1/p')
    echo "📊 Item criado: $ITEM_ID"
  else
    echo "📊 Item já existe: $ITEM_ID"
  fi
done

echo "✅ Seeder concluído!"
