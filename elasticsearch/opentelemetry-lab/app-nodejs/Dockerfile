FROM node:18

ENV NODE_TLS_REJECT_UNAUTHORIZED=0

WORKDIR /usr/src/app
COPY . .

RUN npm install

CMD ["node", "app.js"]
