FROM alpine:3.19

RUN sed -i 's|https://dl-cdn.alpinelinux.org|http://dl-cdn.alpinelinux.org|g' /etc/apk/repositories && \
    apk update && \
    apk add --no-cache curl bash

COPY seed_zabbix.sh /seed/seed_zabbix.sh
RUN chmod +x /seed/seed_zabbix.sh

# ENV: pode ser sobrescrito pelo docker-compose.yml
ENV ZBX_URL=http://zabbix-web:8080/api_jsonrpc.php \
    ZBX_USER=Admin \
    ZBX_PASS=zabbix \
    ZBX_GROUP=DemoGroup \
    ZBX_TEMPLATE=Linux\ by\ Zabbix\ agent \
    ZBX_HOSTS="192.168.0.101,192.168.0.102,192.168.0.103"

# 👇 Usa bash explicitamente no CMD
CMD ["/bin/bash", "/seed/seed_zabbix.sh"]
