#!/bin/sh
set -e

echo "⏳ Aguardando Zabbix Web ficar disponível..."
until curl -s -o /dev/null "$ZBX_URL"; do
  sleep 5
done
echo "✅ Zabbix Web está no ar!"

# Login e pegar token (sem jq)
AUTH_PAYLOAD="{\"jsonrpc\":\"2.0\",\"method\":\"user.login\",\"params\":{\"user\":\"$ZBX_USER\",\"password\":\"$ZBX_PASS\"},\"id\":1}"
AUTH_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' -d "$AUTH_PAYLOAD" "$ZBX_URL")
AUTH_TOKEN=$(echo "$AUTH_RESPONSE" | sed -n 's|.*"result":"\([^"]*\)".*|\1|p')

if [ -z "$AUTH_TOKEN" ]; then
  echo "❌ Erro ao obter token de autenticação. Resposta:"
  echo "$AUTH_RESPONSE"
  exit 1
fi

echo "🔑 Token obtido: $AUTH_TOKEN"

# Criar grupo
GROUP_PAYLOAD="{\"jsonrpc\":\"2.0\",\"method\":\"hostgroup.get\",\"params\":{\"filter\":{\"name\":\"$ZBX_GROUP\"}},\"auth\":\"$AUTH_TOKEN\",\"id\":1}"
GROUP_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' -d "$GROUP_PAYLOAD" "$ZBX_URL")
GROUP_ID=$(echo "$GROUP_RESPONSE" | sed -n 's|.*"groupid":"\([^"]*\)".*|\1|p')

if [ -z "$GROUP_ID" ]; then
  GROUP_CREATE_PAYLOAD="{\"jsonrpc\":\"2.0\",\"method\":\"hostgroup.create\",\"params\":{\"name\":\"$ZBX_GROUP\"},\"auth\":\"$AUTH_TOKEN\",\"id\":1}"
  GROUP_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' -d "$GROUP_CREATE_PAYLOAD" "$ZBX_URL")
  GROUP_ID=$(echo "$GROUP_RESPONSE" | sed -n 's|.*"groupids":\["\([^"]*\)"\].*|\1|p')
  echo "📦 Grupo criado: $GROUP_ID"
else
  echo "📦 Grupo já existe: $GROUP_ID"
fi

# Obter template
TEMPLATE_PAYLOAD="{\"jsonrpc\":\"2.0\",\"method\":\"template.get\",\"params\":{\"filter\":{\"host\":\"$ZBX_TEMPLATE\"}},\"auth\":\"$AUTH_TOKEN\",\"id\":1}"
TEMPLATE_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' -d "$TEMPLATE_PAYLOAD" "$ZBX_URL")
TEMPLATE_ID=$(echo "$TEMPLATE_RESPONSE" | sed -n 's|.*"templateid":"\([^"]*\)".*|\1|p')

echo "📋 Template encontrado: $TEMPLATE_ID"

# Criar hosts
IFS=',' read -r -a HOSTS_ARRAY <<EOF
$ZBX_HOSTS
EOF

for HOST in "${HOSTS_ARRAY[@]}"; do
  # Verifica se já existe
  HOST_GET_PAYLOAD="{\"jsonrpc\":\"2.0\",\"method\":\"host.get\",\"params\":{\"filter\":{\"host\":\"$HOST\"}},\"auth\":\"$AUTH_TOKEN\",\"id\":1}"
  HOST_GET_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' -d "$HOST_GET_PAYLOAD" "$ZBX_URL")
  HOST_ID=$(echo "$HOST_GET_RESPONSE" | sed -n 's|.*"hostid":"\([^"]*\)".*|\1|p')

  if [ -z "$HOST_ID" ]; then
    HOST_CREATE_PAYLOAD="{
      \"jsonrpc\":\"2.0\",\"method\":\"host.create\",\"params\":{
        \"host\":\"$HOST\",
        \"interfaces\":[{\"type\":1,\"main\":1,\"useip\":1,\"ip\":\"$HOST\",\"dns\":\"\",\"port\":\"10050\"}],
        \"groups\":[{\"groupid\":\"$GROUP_ID\"}],
        \"templates\":[{\"templateid\":\"$TEMPLATE_ID\"}]
      },\"auth\":\"$AUTH_TOKEN\",\"id\":1}"
    HOST_CREATE_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' -d "$HOST_CREATE_PAYLOAD" "$ZBX_URL")
    HOST_ID=$(echo "$HOST_CREATE_RESPONSE" | sed -n 's|.*"hostids":\["\([^"]*\)"\].*|\1|p')
    echo "🖥 Host criado: $HOST_ID ($HOST)"
  else
    echo "🖥 Host já existe: $HOST_ID ($HOST)"
  fi

  # Criar item trapper
  ITEM_GET_PAYLOAD="{
    \"jsonrpc\":\"2.0\",\"method\":\"item.get\",\"params\":{\"hostids\":\"$HOST_ID\",\"filter\":{\"key_\":\"custom.trapper.random\"}},\"auth\":\"$AUTH_TOKEN\",\"id\":1}"
  ITEM_GET_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' -d "$ITEM_GET_PAYLOAD" "$ZBX_URL")
  ITEM_ID=$(echo "$ITEM_GET_RESPONSE" | sed -n 's|.*"itemid":"\([^"]*\)".*|\1|p')

  if [ -z "$ITEM_ID" ]; then
    ITEM_CREATE_PAYLOAD="{
      \"jsonrpc\":\"2.0\",\"method\":\"item.create\",\"params\":{
        \"name\":\"Custom Random Value\",
        \"key_\":\"custom.trapper.random\",
        \"hostid\":\"$HOST_ID\",
        \"type\":2,\"value_type\":3,\"delay\":\"0\"
      },\"auth\":\"$AUTH_TOKEN\",\"id\":1}"
    ITEM_CREATE_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' -d "$ITEM_CREATE_PAYLOAD" "$ZBX_URL")
    ITEM_ID=$(echo "$ITEM_CREATE_RESPONSE" | sed -n 's|.*"itemids":\["\([^"]*\)"\].*|\1|p')
    echo "📊 Item criado: $ITEM_ID"
  else
    echo "📊 Item já existe: $ITEM_ID"
  fi
done

echo "✅ Seeder concluído!"
