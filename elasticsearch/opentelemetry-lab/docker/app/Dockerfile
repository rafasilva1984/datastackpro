FROM node:18

ENV NODE_TLS_REJECT_UNAUTHORIZED=0

WORKDIR /usr/src/app
COPY . .

RUN npm config set strict-ssl false && \
    npm config set registry https://registry.npmjs.org/ && \
    npm install

CMD ["node", "app.js"]
