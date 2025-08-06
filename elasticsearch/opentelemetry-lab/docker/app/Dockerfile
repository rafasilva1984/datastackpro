# app-nodejs/Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm config set strict-ssl false && \
    npm config set registry https://registry.npmjs.org/ && \
    npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
