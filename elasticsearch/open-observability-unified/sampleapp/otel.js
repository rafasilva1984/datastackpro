const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: process.env.OTEL_SERVICE_NAME || 'sampleapp',
    [SemanticResourceAttributes.SERVICE_VERSION]: process.env.SERVICE_VERSION || '1.0.0',
  }),
  traceExporter: undefined, // will use OTLP HTTP via env
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start().then(() => {
  console.log('OpenTelemetry SDK started');
}).catch((err) => {
  console.error('Error starting OpenTelemetry', err);
});
