# Imagem base
FROM alpine:3.19

# Troca o repositório para usar HTTP (evita erros de certificado SSL)
RUN sed -i 's|https://dl-cdn.alpinelinux.org|http://dl-cdn.alpinelinux.org|g' /etc/apk/repositories && \
    apk add --no-cache curl bash sed

# Copia o script de seed para dentro do container
COPY seed_zabbix.sh /seed/seed_zabbix.sh
RUN chmod +x /seed/seed_zabbix.sh

# Define o script como entrypoint
ENTRYPOINT ["/seed/seed_zabbix.sh"]
