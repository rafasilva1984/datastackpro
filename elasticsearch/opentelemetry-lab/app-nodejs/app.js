
const express = require('express');
const app = express();
const port = 3000;

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: 'http://apm-server:8200'
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();

app.get('/login', (_, res) => setTimeout(() => res.send('Login efetuado'), 100));
app.get('/checkout', (_, res) => setTimeout(() => res.send('Checkout ok'), 200));
app.get('/error', () => { throw new Error('Erro proposital'); });
app.listen(port, () => console.log(`App rodando na porta ${port}`));
