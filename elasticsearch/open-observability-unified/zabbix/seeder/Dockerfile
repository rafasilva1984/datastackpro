FROM debian:bookworm-slim

# Instala curl, bash e sed com apt
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl bash sed ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copia o script para dentro do container
COPY seed_zabbix.sh /seed/seed_zabbix.sh

# Permissão de execução
RUN chmod +x /seed/seed_zabbix.sh

# Entrypoint padrão
ENTRYPOINT ["/seed/seed_zabbix.sh"]
