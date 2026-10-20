FROM node:22-bookworm

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY . .

ENV PORT=8000
EXPOSE 8000

CMD ["node", "server.js"]