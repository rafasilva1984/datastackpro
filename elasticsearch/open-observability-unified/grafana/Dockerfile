FROM grafana/grafana:11.1.0

# Instala o plugin Zabbix para Grafana
RUN grafana-cli plugins install alexanderzobnin-zabbix-datasource

# Reinicia o servidor do Grafana automaticamente após instalação
ENV GF_INSTALL_PLUGINS=alexanderzobnin-zabbix-datasource
