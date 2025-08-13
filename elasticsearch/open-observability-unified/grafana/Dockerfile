FROM grafana/grafana:11.1.0

USER root

# Instala unzip e certificados necessários
RUN apk add --no-cache ca-certificates unzip && update-ca-certificates

# Copia e instala o plugin manualmente
COPY plugins/alexanderzobnin-zabbix-app.zip /tmp/zabbix.zip
RUN mkdir -p /var/lib/grafana/plugins/zabbix && \
    unzip /tmp/zabbix.zip -d /var/lib/grafana/plugins/zabbix && \
    rm /tmp/zabbix.zip

USER grafana
