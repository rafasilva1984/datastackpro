FROM node:20-alpine

WORKDIR /app

# Copia apenas o package.json (sem o lock para evitar conflitos)
COPY package.json ./

# Configura npm para ignorar SSL, usar registry oficial e instalar dependências sem travar em conflitos de peer
RUN npm config set strict-ssl false \
 && npm config set registry https://registry.npmjs.org \
 && npm install --omit=dev --legacy-peer-deps

# Copia o restante da aplicação
COPY . .

ENV APP_PORT=3000
CMD ["node", "-r", "./otel.js", "app.js"]
