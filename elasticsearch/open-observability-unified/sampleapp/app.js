const express = require('express');
const fs = require('fs');
const path = require('path');
const pino = require('pino');
const pinoPretty = require('pino-pretty');
const client = require('prom-client');

const LOG_DIR = process.env.LOG_DIR || '/var/log/sampleapp';
fs.mkdirSync(LOG_DIR, { recursive: true });

const logger = pino({ level: 'info' }, pino.multistream([
  { stream: fs.createWriteStream(path.join(LOG_DIR, 'app.log'), { flags: 'a' }) },
  { stream: pinoPretty({ colorize: false }) }
]));

const app = express();
const register = new client.Registry();
client.collectDefaultMetrics({ register });

const reqCounter = new client.Counter({
  name: 'sampleapp_http_requests_total',
  help: 'Total HTTP requests by route and status',
  labelNames: ['route', 'status'],
});
register.registerMetric(reqCounter);

function inc(route, status) { reqCounter.inc({ route, status: String(status) }); }

app.get('/health', (req, res) => res.send('ok'));

app.get('/login', (req, res) => { logger.info({ route: 'login', status: 200 }, 'login ok'); inc('login', 200); res.send('login ok'); });
app.get('/checkout', (req, res) => { logger.info({ route: 'checkout', status: 200 }, 'checkout ok'); inc('checkout', 200); res.send('checkout ok'); });
app.get('/error', (req, res) => { logger.error({ route: 'error', status: 500 }, 'simulated error'); inc('error', 500); res.status(500).send('error'); });

app.get('/metrics', async (_req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

const port = process.env.APP_PORT || 3000;
app.listen(port, () => logger.info({ port }, 'sampleapp started'));
