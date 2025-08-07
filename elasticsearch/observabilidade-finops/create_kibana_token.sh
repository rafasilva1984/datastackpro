#!/bin/bash
echo "Gerando token de service account para o Kibana..."

docker exec -it elasticsearch \
  bin/elasticsearch-service-tokens create elastic/kibana kibana-token

echo ""
echo "Copie o token gerado e substitua na variável ELASTICSEARCH_SERVICE_ACCOUNT_TOKEN no docker-compose.yml"
