FROM alpine:3.19

# Instala curl, bash e sed
RUN apk add --no-cache curl bash sed

# Copia o script de seed
COPY seed_zabbix.sh /seed/seed_zabbix.sh

# Entrypoint padrão
ENTRYPOINT ["/seed/seed_zabbix.sh"]
