FROM grafana/grafana:11.1.0

# Garante que os certificados CA estejam presentes
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl && \
    update-ca-certificates && \
    grafana-cli plugins install alexanderzobnin-zabbix-datasource && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER grafana
