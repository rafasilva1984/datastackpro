    #!/usr/bin/env bash
    set -euo pipefail

    ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    if [ -f "$ROOT_DIR/.env" ]; then
      # shellcheck disable=SC1091
      source "$ROOT_DIR/.env"
    else
      echo "Arquivo .env não encontrado. Copie de .env.example" >&2
      exit 1
    fi

    ES="${STACK_HOST:-http://localhost:9200}"
    AUTH="elastic:${ELASTIC_PASSWORD}"

    # Detectar GNU date (macOS usa gdate)
    DATECMD="date"
    if ! ${DATECMD} -d "2020-01-01" >/dev/null 2>&1; then
      if command -v gdate >/dev/null 2>&1; then
        DATECMD="gdate"
      else
        echo "GNU date não encontrado. Instale coreutils (brew install coreutils) ou rode em Linux." >&2
        exit 1
      fi
    fi

    echo "⏳ Aguardando Elasticsearch ficar disponível..."
    until curl -s -u "$AUTH" "$ES" >/dev/null; do
      sleep 2
      echo -n "."
    done
    echo " ok"

    echo "📐 Criando ILM, templates e pipeline..."
    curl -s -u "$AUTH" -H 'Content-Type: application/json' -X PUT "$ES/_ilm/policy/app-logs-ilm"       -d @"$ROOT_DIR/elastic/ilm/app-logs-ilm.json" >/dev/null

    curl -s -u "$AUTH" -H 'Content-Type: application/json' -X POST "$ES/_index_template"       -d @"$ROOT_DIR/elastic/templates/app-logs-template.json" >/dev/null

    curl -s -u "$AUTH" -H 'Content-Type: application/json' -X POST "$ES/_index_template"       -d @"$ROOT_DIR/elastic/templates/biz-metrics-template.json" >/dev/null

    curl -s -u "$AUTH" -H 'Content-Type: application/json' -X PUT "$ES/_ingest/pipeline/app-logs-pipeline"       -d @"$ROOT_DIR/elastic/pipelines/app-logs-pipeline.json" >/dev/null

    echo "🧱 Criando data streams..."
    curl -s -u "$AUTH" -H 'Content-Type: application/json' -X PUT "$ES/_data_stream/app-logs-default" >/dev/null
    curl -s -u "$AUTH" -H 'Content-Type: application/json' -X PUT "$ES/_data_stream/biz-metrics-default" >/devnull 2>/dev/null || true

    echo "🚚 Gerando carga sintética de ${DATA_DAYS} dia(s)..."

    services=("checkout" "login" "catalog")
    regions=("sa-east-1" "us-east-1")
    envs=("prod")

    # timestamps
    now_epoch=$(${DATECMD} +%s)
    minutes_back=$(( DATA_DAYS * 1440 ))
    start_epoch=$(( now_epoch - minutes_back * 60 ))

    # Função para ISO8601
    to_iso() {
      ${DATECMD} -u -d "@$1" +"%Y-%m-%dT%H:%M:%S.000Z"
    }

    # Gerar biz-metrics: um doc por minuto consolidado para 'checkout'
    echo "📈 Inserindo biz-metrics..."
    bulk_file="$(mktemp)"
    for ((m=0; m<=minutes_back; m++)); do
      ts=$(( start_epoch + m*60 ))
      iso="$(to_iso "$ts")"
      active_users=$(( (RANDOM % 40) + 60 ))             # 60-99
      transactions=$(( (RANDOM % 30) + 50 ))             # 50-79
      errors=$(( (RANDOM % 6) ))                         # 0-5
      avg_ticket="${AVG_TICKET:-150.0}"
      conv_loss="${CONVERSION_LOSS_FACTOR:-0.7}"
      # Receita prevista sem erros e receita real
      predicted=$(python3 - <<PY
avg=${avg_ticket}; tx=${transactions}
print(f"{avg*tx:.2f}")
PY
)
      real_tx=$(( transactions - errors ))
      if [ $real_tx -lt 0 ]; then real_tx=0; fi
      revenue=$(python3 - <<PY
avg=${avg_ticket}; tx=${real_tx}
print(f"{avg*tx:.2f}")
PY
)
      loss=$(python3 - <<PY
p=${predicted}; r=${revenue}
print(f"{float(p)-float(r):.2f}")
PY
)
      conv_rate=$(python3 - <<PY
tx=${transactions}; au=${active_users}
print( round( (tx/au) if au>0 else 0.0, 3) )
PY
)
      cat >>"$bulk_file" <<EOF
{ "create": { "_index": "biz-metrics-default" } }
{ "@timestamp": "$iso", "active_users": $active_users, "transactions": $transactions, "errors_checkout": $errors, "avg_ticket": $avg_ticket, "revenue": $revenue, "predicted_revenue_without_errors": $predicted, "loss_due_to_errors": $loss, "conversion_rate": $conv_rate, "service": "checkout", "is_anomaly": false }
EOF
    done
    curl -s -u "$AUTH" -H 'Content-Type: application/x-ndjson' -X POST "$ES/_bulk" --data-binary @"$bulk_file" >/dev/null
    rm -f "$bulk_file"

    # Gerar app-logs: vários docs por minuto por serviço/rota
    echo "📝 Inserindo app-logs... (isso pode levar alguns segundos)"
    routes=("POST /checkout" "POST /login" "GET /catalog")
    bulk_file="$(mktemp)"
    for svc in "${services[@]}"; do
      for ((m=0; m<=minutes_back; m++)); do
        ts=$(( start_epoch + m*60 ))
        for ((i=0; i<${DOCS_PER_MINUTE}; i++)); do
          iso="$(to_iso "$ts")"
          region="${regions[$RANDOM % ${#regions[@]}]}"
          route="${routes[$RANDOM % ${#routes[@]}]}"
          status_pool=(200 200 200 200 500 502 504 404 201)
          status="${status_pool[$RANDOM % ${#status_pool[@]}]}"
          latency=$(( (RANDOM % 900) + 50 )) # 50-949 ms
          is_error=false
          if [ $status -ge 500 ]; then is_error=true; fi
          user_id=$(( (RANDOM % 900000) + 100000 ))
          cat >>"$bulk_file" <<EOF
{ "create": { "_index": "app-logs-default", "pipeline": "app-logs-pipeline" } }
{ "@timestamp": "$iso", "service": { "name": "$svc" }, "event": { "dataset": "app.synthetic" }, "http": { "response": { "status_code": $status } }, "latency_ms": $latency, "user": { "id": "$user_id" }, "region": "$region", "env": "prod", "route": "$route", "is_error": $is_error }
EOF
        done
      done
    done
    curl -s -u "$AUTH" -H 'Content-Type: application/x-ndjson' -X POST "$ES/_bulk" --data-binary @"$bulk_file" >/dev/null
    rm -f "$bulk_file"

    echo "✅ Carga concluída."
