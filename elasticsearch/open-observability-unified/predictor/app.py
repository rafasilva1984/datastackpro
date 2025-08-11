import os, time, threading, requests, numpy as np
from flask import Flask, jsonify
from prometheus_client import Gauge, generate_latest, CONTENT_TYPE_LATEST

PROM_URL = os.getenv("PROM_URL", "http://prometheus:9090")
TARGET_EXPR = os.getenv("TARGET_EXPR", "rate(sampleapp_http_requests_total[5m])")
TARGET_THRESHOLD = float(os.getenv("TARGET_THRESHOLD", "50"))
POLL_SECONDS = int(os.getenv("POLL_SECONDS", "60"))

app = Flask(__name__)

time_to_thresh = Gauge("time_to_threshold_seconds",
                       "Tempo previsto (s) para atingir o limiar",
                       ["metric", "threshold"])

last_calc = {"ok": False, "msg": "not yet"}

def query_prom_range(expr, minutes=60, step="30s"):
    end = int(time.time())
    start = end - minutes * 60
    url = f"{PROM_URL}/api/v1/query_range"
    r = requests.get(url, params={"query": expr, "start": start, "end": end, "step": step}, timeout=10)
    r.raise_for_status()
    data = r.json()
    if data["status"] != "success":
        raise RuntimeError("Prometheus query failed")
    return data["data"]["result"]

def forecast_time_to_threshold(series):
    if len(series) < 5:
        return float("inf")
    xs = np.array([float(ts) for ts, _ in series])
    ys = np.array([float(val) for _, val in series])
    slope, intercept = np.polyfit(xs, ys, 1)
    y_last = ys[-1]
    if slope <= 0 or y_last >= TARGET_THRESHOLD:
        return float("inf")
    t_hit = (TARGET_THRESHOLD - intercept) / slope
    seconds = t_hit - xs[-1]
    return seconds if seconds > 0 else float("inf")

def compute_loop():
    global last_calc
    while True:
        try:
            results = query_prom_range(TARGET_EXPR, minutes=60, step="30s")
            min_time = float("inf")
            for serie in results:
                values = serie["values"]
                tt = forecast_time_to_threshold(values)
                if tt < min_time:
                    min_time = tt
            time_to_thresh.labels(metric="sampleapp_rps", threshold=str(TARGET_THRESHOLD)).set(min_time)
            last_calc = {"ok": True, "seconds": min_time}
        except Exception as e:
            last_calc = {"ok": False, "msg": str(e)}
        time.sleep(POLL_SECONDS)

@app.route("/health")
def health():
    return jsonify({"status": "ok", "last": last_calc})

@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}

if __name__ == "__main__":
    th = threading.Thread(target=compute_loop, daemon=True)
    th.start()
    app.run(host="0.0.0.0", port=8000)
