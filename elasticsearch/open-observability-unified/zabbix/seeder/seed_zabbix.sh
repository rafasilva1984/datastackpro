#!/bin/bash
set -e

echo "⏳ Aguardando Zabbix Web ficar disponível..."
until curl -s -o /dev/null "$ZBX_URL"; do
  sleep 5
done
echo "✅ Zabbix Web está no ar!"

# Realiza login e captura token
AUTH_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"user.login\",\"params\":{\"user\":\"${ZBX_USER}\",\"password\":\"${ZBX_PASS}\"},\"id\":1}" \
  "$ZBX_URL")

AUTH_TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"result":"[^"]*"' | cut -d':' -f2 | tr -d '"')

if [ -z "$AUTH_TOKEN" ]; then
  echo "❌ Erro ao obter token de autenticação. Verifique usuário e senha."
  echo "Resposta completa:"
  echo "$AUTH_RESPONSE"
  exit 1
fi

echo "🔑 Token obtido com sucesso."

# Verifica ou cria grupo
GROUP_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"hostgroup.get\",\"params\":{\"filter\":{\"name\":\"${ZBX_GROUP}\"}},\"auth\":\"${AUTH_TOKEN}\",\"id\":1}" \
  "$ZBX_URL")

GROUP_ID=$(echo "$GROUP_RESPONSE" | grep -o '"groupid":"[^"]*"' | cut -d':' -f2 | tr -d '"')

if [ -z "$GROUP_ID" ]; then
  CREATE_GROUP_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d "{\"jsonrpc\":\"2.0\",\"method\":\"hostgroup.create\",\"params\":{\"name\":\"${ZBX_GROUP}\"},\"auth\":\"${AUTH_TOKEN}\",\"id\":1}" \
    "$ZBX_URL")
  GROUP_ID=$(echo "$CREATE_GROUP_RESPONSE" | grep -o '"groupids":\["[^"]*"\]' | grep -o '[0-9]*')
  echo "📦 Grupo criado: $GROUP_ID"
else
  echo "📦 Grupo já existe: $GROUP_ID"
fi

# Busca o template
TEMPLATE_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"template.get\",\"params\":{\"filter\":{\"host\":\"${ZBX_TEMPLATE}\"}},\"auth\":\"${AUTH_TOKEN}\",\"id\":1}" \
  "$ZBX_URL")

TEMPLATE_ID=$(echo "$TEMPLATE_RESPONSE" | grep -o '"templateid":"[^"]*"' | cut -d':' -f2 | tr -d '"')

if [ -z "$TEMPLATE_ID" ]; then
  echo "❌ Template '${ZBX_TEMPLATE}' não encontrado."
  exit 1
else
  echo "📜 Template encontrado: $TEMPLATE_ID"
fi

# Criação dos hosts
IFS=',' read -ra HOSTS <<< "$ZBX_HOSTS"
for HOST in "${HOSTS[@]}"; do
  HOST_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d "{\"jsonrpc\":\"2.0\",\"method\":\"host.get\",\"params\":{\"filter\":{\"host\":\"${HOST}\"}},\"auth\":\"${AUTH_TOKEN}\",\"id\":1}" \
    "$ZBX_URL")

  HOST_ID=$(echo "$HOST_RESPONSE" | grep -o '"hostid":"[^"]*"' | cut -d':' -f2 | tr -d '"')

  if [ -z "$HOST_ID" ]; then
    CREATE_HOST_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
      -d "{
        \"jsonrpc\":\"2.0\",
        \"method\":\"host.create\",
        \"params\":{
          \"host\":\"${HOST}\",
          \"interfaces\":[
            {
              \"type\":1,
              \"main\":1,
              \"useip\":1,
              \"ip\":\"${HOST}\",
              \"dns\":\"\",
              \"port\":\"10050\"
            }
          ],
          \"groups\":[{\"groupid\":\"${GROUP_ID}\"}],
          \"templates\":[{\"templateid\":\"${TEMPLATE_ID}\"}]
        },
        \"auth\":\"${AUTH_TOKEN}\",
        \"id\":1
      }" "$ZBX_URL")
    HOST_ID=$(echo "$CREATE_HOST_RESPONSE" | grep -o '"hostids":\["[^"]*"\]' | grep -o '[0-9]*')
    echo "🖥 Host criado: $HOST_ID ($HOST)"
  else
    echo "🖥 Host já existe: $HOST_ID ($HOST)"
  fi

  # Criar item trapper custom.trapper.random
  ITEM_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d "{\"jsonrpc\":\"2.0\",\"method\":\"item.get\",\"params\":{\"hostids\":\"${HOST_ID}\",\"filter\":{\"key_\":\"custom.trapper.random\"}},\"auth\":\"${AUTH_TOKEN}\",\"id\":1}" \
    "$ZBX_URL")
  ITEM_ID=$(echo "$ITEM_RESPONSE" | grep -o '"itemid":"[^"]*"' | cut -d':' -f2 | tr -d '"')

  if [ -z "$ITEM_ID" ]; then
    CREATE_ITEM_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
      -d "{
        \"jsonrpc\":\"2.0\",
        \"method\":\"item.create\",
        \"params\":{
          \"name\":\"Custom Random Value\",
          \"key_\":\"custom.trapper.random\",
          \"hostid\":\"${HOST_ID}\",
          \"type\":2,
          \"value_type\":3,
          \"delay\":\"0\"
        },
        \"auth\":\"${AUTH_TOKEN}\",
        \"id\":1
      }" "$ZBX_URL")
    ITEM_ID=$(echo "$CREATE_ITEM_RESPONSE" | grep -o '"itemids":\["[^"]*"\]' | grep -o '[0-9]*')
    echo "📊 Item criado: $ITEM_ID"
  else
    echo "📊 Item já existe: $ITEM_ID"
  fi
done

echo "✅ Seeder concluído com sucesso!"
