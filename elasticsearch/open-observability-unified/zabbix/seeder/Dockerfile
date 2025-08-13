FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl bash sed ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY seed_zabbix.sh /seed/seed_zabbix.sh

RUN chmod +x /seed/seed_zabbix.sh

ENTRYPOINT ["/seed/seed_zabbix.sh"]
