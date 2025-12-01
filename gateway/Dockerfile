FROM node:20-alpine AS deps

WORKDIR /app

COPY package*.json ./

RUN npm install --omit=dev && \
    npm cache clean --force

FROM node:20-alpine

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules

COPY --chown=nodejs:nodejs . .

USER nodejs

EXPOSE 5921

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD node -e "require('http').get('http://localhost:5921/health', (r) => { process.exit(r.statusCode === 200 ? 0 : 1); })"

CMD ["node", "src/gateway.js"]
