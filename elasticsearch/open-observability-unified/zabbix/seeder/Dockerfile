FROM alpine:3.19

RUN apk add --no-cache curl jq bash

COPY seed_zabbix.sh /seed/seed_zabbix.sh

RUN chmod +x /seed/seed_zabbix.sh

CMD ["/seed/seed_zabbix.sh"]
