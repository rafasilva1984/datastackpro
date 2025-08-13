#!/bin/sh
set -e

echo "⏳ Aguardando Zabbix API responder corretamente..."

# Aguarda até que a API JSON-RPC esteja funcional
while true; do
  RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","method":"apiinfo.version","id":1}' "$ZBX_URL")

  if echo "$RESPONSE" | grep -q '"error"'; then
    echo "✅ Zabbix API está ativa! Resposta: $RESPONSE"
    break
  else
    echo "🔁 Aguardando... (resposta atual: $RESPONSE)"
    sleep 3
  fi
done

# Login
AUTH_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d "{
        \"jsonrpc\": \"2.0\",
        \"method\": \"user.login\",
        \"params\": {
          \"username\": \"$ZBX_USER\",
          \"password\": \"$ZBX_PASS\"
        },
        \"id\": 1
      }" "$ZBX_URL")

AUTH_TOKEN=$(echo "$AUTH_RESPONSE" | sed -n 's/.*"result":"\([^"]*\)".*/\1/p')

if [ -z "$AUTH_TOKEN" ]; then
  echo "❌ Erro ao obter token de autenticação. Verifique usuário e senha."
  echo "Resposta completa:"
  echo "$AUTH_RESPONSE"
  exit 1
fi

echo "🔑 Token obtido: $AUTH_TOKEN"

# Criação ou verificação de grupo
GROUP_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d "{
        \"jsonrpc\": \"2.0\",
        \"method\": \"hostgroup.get\",
        \"params\": {\"filter\": {\"name\": \"$ZBX_GROUP\"}},
        \"auth\": \"$AUTH_TOKEN\",
        \"id\": 1
      }" "$ZBX_URL")

GROUP_ID=$(echo "$GROUP_RESPONSE" | sed -n 's/.*"groupid":"\([^"]*\)".*/\1/p')

if [ -z "$GROUP_ID" ]; then
  CREATE_GROUP_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d "{
          \"jsonrpc\": \"2.0\",
          \"method\": \"hostgroup.create\",
          \"params\": {\"name\": \"$ZBX_GROUP\"},
          \"auth\": \"$AUTH_TOKEN\",
          \"id\": 1
        }" "$ZBX_URL")
  GROUP_ID=$(echo "$CREATE_GROUP_RESPONSE" | sed -n 's/.*"groupids":\["\([^"]*\)"\].*/\1/p')
  echo "📦 Grupo criado: $GROUP_ID"
else
  echo "📦 Grupo já existe: $GROUP_ID"
fi

# Busca o ID do template
TEMPLATE_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d "{
        \"jsonrpc\": \"2.0\",
        \"method\": \"template.get\",
        \"params\": {\"filter\": {\"host\": \"$ZBX_TEMPLATE\"}},
        \"auth\": \"$AUTH_TOKEN\",
        \"id\": 1
      }" "$ZBX_URL")

TEMPLATE_ID=$(echo "$TEMPLATE_RESPONSE" | sed -n 's/.*"templateid":"\([^"]*\)".*/\1/p')

if [ -z "$TEMPLATE_ID" ]; then
  echo "❌ Template '$ZBX_TEMPLATE' não encontrado. Abortando."
  exit 1
fi

echo "📋 Template encontrado: $TEMPLATE_ID"

# Lê e cria os hosts
IFS=',' read -r -a HOSTS <<< "$ZBX_HOSTS"

for HOST in "${HOSTS[@]}"; do
  echo "⚙️  Processando host: $HOST"

  HOST_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d "{
          \"jsonrpc\": \"2.0\",
          \"method\": \"host.get\",
          \"params\": {\"filter\": {\"host\": \"$HOST\"}},
          \"auth\": \"$AUTH_TOKEN\",
          \"id\": 1
        }" "$ZBX_URL")

  HOST_ID=$(echo "$HOST_RESPONSE" | sed -n 's/.*"hostid":"\([^"]*\)".*/\1/p')

  if [ -z "$HOST_ID" ]; then
    CREATE_HOST_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
      -d "{
            \"jsonrpc\": \"2.0\",
            \"method\": \"host.create\",
            \"params\": {
              \"host\": \"$HOST\",
              \"interfaces\": [{
                \"type\": 1,
                \"main\": 1,
                \"useip\": 1,
                \"ip\": \"$HOST\",
                \"dns\": \"\",
                \"port\": \"10050\"
              }],
              \"groups\": [{\"groupid\": \"$GROUP_ID\"}],
              \"templates\": [{\"templateid\": \"$TEMPLATE_ID\"}]
            },
            \"auth\": \"$AUTH_TOKEN\",
            \"id\": 1
          }" "$ZBX_URL")
    HOST_ID=$(echo "$CREATE_HOST_RESPONSE" | sed -n 's/.*"hostids":\["\([^"]*\)"\].*/\1/p')
    echo "🖥 Host criado: $HOST_ID"
  else
    echo "🖥 Host já existe: $HOST_ID"
  fi

  # Item trapper
  ITEM_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d "{
          \"jsonrpc\": \"2.0\",
          \"method\": \"item.get\",
          \"params\": {
            \"hostids\": \"$HOST_ID\",
            \"filter\": {\"key_\": \"custom.trapper.random\"}
          },
          \"auth\": \"$AUTH_TOKEN\",
          \"id\": 1
        }" "$ZBX_URL")

  ITEM_ID=$(echo "$ITEM_RESPONSE" | sed -n 's/.*"itemid":"\([^"]*\)".*/\1/p')

  if [ -z "$ITEM_ID" ]; then
    CREATE_ITEM_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
      -d "{
            \"jsonrpc\": \"2.0\",
            \"method\": \"item.create\",
            \"params\": {
              \"name\": \"Custom Random Value\",
              \"key_\": \"custom.trapper.random\",
              \"hostid\": \"$HOST_ID\",
              \"type\": 2,
              \"value_type\": 3,
              \"delay\": \"0\"
            },
            \"auth\": \"$AUTH_TOKEN\",
            \"id\": 1
          }" "$ZBX_URL")
    ITEM_ID=$(echo "$CREATE_ITEM_RESPONSE" | sed -n 's/.*"itemids":\["\([^"]*\)"\].*/\1/p')
    echo "📊 Item criado: $ITEM_ID"
  else
    echo "📊 Item já existe: $ITEM_ID"
  fi
done

echo "✅ Seeder concluído com sucesso!"
