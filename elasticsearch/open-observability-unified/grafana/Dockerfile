FROM grafana/grafana:11.1.0

# Troca para root para instalar dependências
USER root

# Usa apk (Alpine) em vez de apt-get, instala curl e certificados, e adiciona o plugin Zabbix
RUN apk add --no-cache curl ca-certificates && \
    grafana-cli plugins install alexanderzobnin-zabbix-app

# Retorna ao usuário padrão grafana
USER grafana
