// otel.js
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');

// Recurso (service.*)
const resource = new Resource({
  [SemanticResourceAttributes.SERVICE_NAME]: process.env.OTEL_SERVICE_NAME || 'sampleapp',
  [SemanticResourceAttributes.SERVICE_VERSION]: process.env.SERVICE_VERSION || '1.0.0',
});

// Exportador OTLP/HTTP (usa OTEL_EXPORTER_OTLP_ENDPOINT se definido; ex: http://otel-collector:4318)
const traceExporter = new OTLPTraceExporter();

// SDK com auto-instrumentations
const sdk = new NodeSDK({
  resource,
  traceExporter,
  instrumentations: [getNodeAutoInstrumentations()],
});

// Start síncrono (nessa versão não use .then/.catch)
sdk.start();

// Shutdown gracefull
const shutdown = () => {
  sdk.shutdown().finally(() => process.exit(0));
};
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
