const express = require('express');
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node'); // opcional se funcionar

const app = express();

// OpenTelemetry config
const sdk = new NodeSDK({
  instrumentations: [
    require('@opentelemetry/instrumentation-http'),
    require('@opentelemetry/instrumentation-express')
  ]
});

sdk.start();

app.get('/', (req, res) => {
  res.send('Aplicação Node com OpenTelemetry está funcionando!');
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Servidor rodando em http://localhost:${port}`);
});
