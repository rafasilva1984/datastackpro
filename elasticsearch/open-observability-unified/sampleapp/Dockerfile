FROM node:20-alpine

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm config set strict-ssl false && npm ci --omit=dev
COPY . .

ENV APP_PORT=3000
CMD ["node", "-r", "./otel.js", "app.js"]
