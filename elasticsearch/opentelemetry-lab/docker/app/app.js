const express = require('express');
const app = express();
const port = 3000;

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: 'http://localhost:8200/v1/traces',
    headers: {
      'Authorization': 'Basic ' + Buffer.from('elastic:changeme').toString('base64'),
    },
  }),
  serviceName: 'meu-app-node',
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();

app.get('/login', (req, res) => {
  setTimeout(() => {
    res.send('Login efetuado com sucesso');
  }, 100);
});

app.get('/checkout', (req, res) => {
  setTimeout(() => {
    res.send('Checkout realizado');
  }, 200);
});

app.get('/error', (req, res) => {
  throw new Error('Erro simulado!');
});

app.listen(port, () => {
  console.log(`App rodando na porta ${port}`);
});
