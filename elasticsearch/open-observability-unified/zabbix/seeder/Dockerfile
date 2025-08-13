# Imagem base leve
FROM alpine:3.19

# Instala curl, bash e sed
RUN apk add --no-cache curl bash sed

# Copia o script de seed
COPY seed_zabbix.sh /seed/seed_zabbix.sh

# Dá permissão de execução
RUN chmod +x /seed/seed_zabbix.sh

# Executa o script ao subir
CMD ["/seed/seed_zabbix.sh"]
