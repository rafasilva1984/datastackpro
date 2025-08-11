const express = require('express');
const client = require('prom-client');
const pino = require('pino');
const pretty = require('pino-pretty');
const fs = require('fs');
const path = require('path');

const app = express();
const logDir = '/var/log/sampleapp';
fs.mkdirSync(logDir, { recursive: true });
const stream = fs.createWriteStream(path.join(logDir, 'app.log'), { flags: 'a' });
const logger = pino(pretty({ colorize: false }), stream);

const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpRequests = new client.Counter({
  name: 'sampleapp_http_requests_total',
  help: 'Total de requisições HTTP por rota',
  labelNames: ['route', 'status']
});
register.registerMetric(httpRequests);

const httpDuration = new client.Histogram({
  name: 'sampleapp_http_request_duration_ms',
  help: 'Duração das requisições HTTP em ms',
  labelNames: ['route', 'status'],
  buckets: [5, 10, 25, 50, 100, 250, 500, 1000, 2000]
});
register.registerMetric(httpDuration);

function simulateWork(minMs = 20, maxMs = 200) {
  return new Promise((resolve) => setTimeout(resolve, Math.floor(Math.random() * (maxMs - minMs + 1)) + minMs));
}

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.get('/login', async (req, res) => {
  const start = Date.now();
  await simulateWork();
  const status = 200;
  httpRequests.inc({ route: 'login', status });
  httpDuration.observe({ route: 'login', status }, Date.now() - start);
  logger.info({ level: 'info', msg: 'login ok', route: 'login', status, duration_ms: Date.now() - start });
  res.json({ message: 'login ok' });
});

app.get('/checkout', async (req, res) => {
  const start = Date.now();
  await simulateWork(100, 600);
  const status = 200;
  httpRequests.inc({ route: 'checkout', status });
  httpDuration.observe({ route: 'checkout', status }, Date.now() - start);
  logger.info({ level: 'info', msg: 'checkout ok', route: 'checkout', status, duration_ms: Date.now() - start });
  res.json({ message: 'checkout ok' });
});

app.get('/error', async (req, res) => {
  const start = Date.now();
  await simulateWork(50, 150);
  const status = 500;
  httpRequests.inc({ route: 'error', status });
  httpDuration.observe({ route: 'error', status }, Date.now() - start);
  logger.error({ level: 'error', msg: 'forced error', route: 'error', status, duration_ms: Date.now() - start });
  res.status(status).json({ error: 'forced error' });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

const port = process.env.APP_PORT || 3000;
app.listen(port, () => {
  console.log(`Sample app listening on ${port}`);
});
