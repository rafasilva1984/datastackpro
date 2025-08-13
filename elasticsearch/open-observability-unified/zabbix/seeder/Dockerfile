FROM alpine:3.19

# Instala dependências necessárias
RUN apk update && \
    apk add --no-cache bash curl jq

# Copia o script de seed
COPY seed_zabbix.sh /seed/seed_zabbix.sh

# Permissões e execução
RUN chmod +x /seed/seed_zabbix.sh
ENTRYPOINT ["bash", "/seed/seed_zabbix.sh"]
