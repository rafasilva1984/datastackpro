const express = require('express');
const fs = require('fs');
const path = require('path');
const pino = require('pino');
const pinoPretty = require('pino-pretty');

const LOG_DIR = process.env.LOG_DIR || '/var/log/sampleapp';
const LOG_FILE = process.env.LOG_FILE || path.join(LOG_DIR, 'app.log');

// garante diretório
fs.mkdirSync(LOG_DIR, { recursive: true });

// multistream: arquivo (para promtail/filebeat) + stdout (para Docker logs)
const streams = [
  { stream: fs.createWriteStream(LOG_FILE, { flags: 'a' }) },
  { stream: pinoPretty({ colorize: false }) }
];
const logger = pino({ level: 'info' }, pino.multistream(streams));

const app = express();

app.get('/health', (req, res) => res.send('ok'));
app.get('/login', (req, res) => {
  logger.info({ route: 'login', status: 200 }, 'login ok');
  res.send('login ok');
});
app.get('/checkout', (req, res) => {
  logger.info({ route: 'checkout', status: 200 }, 'checkout ok');
  res.send('checkout ok');
});
app.get('/error', (req, res) => {
  logger.error({ route: 'error', status: 500 }, 'simulated error');
  res.status(500).send('error simulated');
});

const port = process.env.APP_PORT || 3000;
app.listen(port, () => logger.info({ port }, 'sampleapp started'));
