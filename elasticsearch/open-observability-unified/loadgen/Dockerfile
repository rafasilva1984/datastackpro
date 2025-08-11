# Usa imagem com curl pronto – evita apk e problemas de CA/proxy
FROM curlimages/curl:8.7.1

WORKDIR /app
COPY scripts/load.sh /app/load.sh

# Garante execução (feito no build, não no runtime)
RUN chmod +x /app/load.sh

# Controla intensidade da carga (segundos)
ENV SLEEP_SECONDS=1

CMD ["/bin/sh", "/app/load.sh"]
