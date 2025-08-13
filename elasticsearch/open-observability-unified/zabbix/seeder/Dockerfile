FROM alpine:3.19

# Corrige repositório SSL e instala pacotes necessários
RUN sed -i 's|https://dl-cdn.alpinelinux.org|http://dl-cdn.alpinelinux.org|g' /etc/apk/repositories && \
    apk add --no-cache curl bash sed jq

# Copia o script de seed
COPY seed_zabbix.sh /seed/seed_zabbix.sh
RUN chmod +x /seed/seed_zabbix.sh

# Executa o script ao iniciar o container
ENTRYPOINT ["/seed/seed_zabbix.sh"]
