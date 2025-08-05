FROM node:18

# Ignorar erros de SSL no Node.js e npm
ENV NODE_TLS_REJECT_UNAUTHORIZED=0

WORKDIR /usr/src/app
COPY . .

# Configurações do npm para ignorar SSL self-signed
RUN npm config set strict-ssl false && \
    npm config set registry https://registry.npmjs.org/ && \
    npm install

CMD ["node", "app.js"]
