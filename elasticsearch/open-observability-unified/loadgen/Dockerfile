FROM curlimages/curl:8.7.1

# /tmp é gravável por qualquer usuário
WORKDIR /tmp

# Define permissão no momento do COPY (não precisa rodar chmod)
COPY --chmod=0755 scripts/load.sh /tmp/load.sh

ENV SLEEP_SECONDS=1

CMD ["/bin/sh", "/tmp/load.sh"]
