FROM grafana/grafana:11.1.0

USER root

# Copia o plugin descompactado (dentro de grafana/zabbix/alexanderzobnin-zabbix-app) para o local correto do Grafana
COPY zabbix/alexanderzobnin-zabbix-app /var/lib/grafana/plugins/alexanderzobnin-zabbix-app

USER grafana

