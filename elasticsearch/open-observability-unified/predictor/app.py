from flask import Flask, jsonify
from prometheus_client import Gauge, generate_latest, CONTENT_TYPE_LATEST
import os, time, requests

PROM_URL = os.getenv("PROM_URL","http://prometheus:9090")
TARGET_EXPR = os.getenv("TARGET_EXPR","rate(sampleapp_http_requests_total[5m])")
TARGET_THRESHOLD = float(os.getenv("TARGET_THRESHOLD","50"))
POLL_SECONDS = int(os.getenv("POLL_SECONDS","60"))

app = Flask(__name__)

g_eta = Gauge('predictor_eta_seconds', 'ETA (segundos) pra atingir o threshold de RPS')
g_threshold = Gauge('predictor_target_threshold', 'Threshold alvo de RPS')
g_current = Gauge('predictor_current_rps', 'RPS atual medido')

last_eta = 0

def query_prom(q):
  r = requests.get(f"{PROM_URL}/api/v1/query", params={"query": q}, timeout=5)
  r.raise_for_status()
  data = r.json()["data"]["result"]
  if not data: return 0.0
  # soma de todas as séries
  return sum(float(v["value"][1]) for v in data)

@app.route("/metrics")
def metrics():
  return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route("/health")
def health():
  return jsonify(status="ok")

def loop():
  global last_eta
  while True:
    try:
      rps = query_prom(TARGET_EXPR)
      g_current.set(rps)
      g_threshold.set(TARGET_THRESHOLD)
      # regressão linear simplificada: se rps == 0, evita div/0
      growth = max(rps - g_current._value.get(), 0.0001)
      # heurística simples: quando rps estável, ETA cresce; com carga, ETA cai
      last_eta = max(0.0, last_eta + (TARGET_THRESHOLD - rps) / max(rps, 0.1))
      g_eta.set(last_eta)
    except Exception as e:
      # evita derrubar o loop
      pass
    time.sleep(POLL_SECONDS)

if __name__ == "__main__":
  import threading
  threading.Thread(target=loop, daemon=True).start()
  app.run(host="0.0.0.0", port=8000)
