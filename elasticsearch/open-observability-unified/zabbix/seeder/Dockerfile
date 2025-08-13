FROM alpine:3.19

# Substitui o mirror padrão para um mais confiável e instala dependências
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/' /etc/apk/repositories && \
    apk add --no-cache curl jq bash

# Copia o script de seed
COPY seed_zabbix.sh /seed/seed_zabbix.sh

# Permissões e execução
RUN chmod +x /seed/seed_zabbix.sh
ENTRYPOINT ["bash", "/seed/seed_zabbix.sh"]
