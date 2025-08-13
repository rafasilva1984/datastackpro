FROM grafana/grafana:11.1.0

USER root

# Copia o plugin já descompactado no host
COPY zabbix /var/lib/grafana/plugins/zabbix

USER grafana
