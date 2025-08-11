FROM node:20-alpine

WORKDIR /app

# instala deps sem lock para evitar conflitos
COPY package.json ./
RUN npm config set strict-ssl false \
 && npm config set registry https://registry.npmjs.org \
 && npm install --omit=dev --legacy-peer-deps

# garante diretório de logs que será montado como volume
RUN mkdir -p /var/log/sampleapp

# copia código
COPY . .

ENV APP_PORT=3000
ENV LOG_DIR=/var/log/sampleapp
ENV LOG_FILE=/var/log/sampleapp/app.log

CMD ["node", "-r", "./otel.js", "app.js"]
