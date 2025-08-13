FROM alpine:3.19

# Instala apenas o necessário (curl, bash e sed)
RUN apk add --no-cache curl bash

# Copia o script para dentro do container
COPY seed_zabbix.sh /seed/seed_zabbix.sh
RUN chmod +x /seed/seed_zabbix.sh

# Variáveis de ambiente padrão (podem ser sobrescritas no docker-compose)
ENV ZBX_URL=http://zabbix-web:8080/api_jsonrpc.php \
    ZBX_USER=Admin \
    ZBX_PASS=zabbix \
    ZBX_GROUP=DemoGroup \
    ZBX_TEMPLATE=Linux\ by\ Zabbix\ agent \
    ZBX_HOSTS="192.168.0.101,192.168.0.102,192.168.0.103"

# Script de inicialização
CMD ["/seed/seed_zabbix.sh"]
