FROM alpine:3.18

RUN apk add --no-cache curl

# Copia o script e define permissão AINDA NO BUILD
WORKDIR /app
COPY scripts/load.sh /app/load.sh
RUN chmod +x /app/load.sh

# Variável opcional para controlar intensidade da carga
ENV SLEEP_SECONDS=1

CMD ["/app/load.sh"]
