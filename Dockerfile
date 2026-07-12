FROM node:24-bookworm-slim

WORKDIR /app
ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
ENV PORT=3500

COPY . /app
RUN rm -rf /app/node_modules \
    && npm install --omit=dev --no-audit --no-fund \
    && mkdir -p /app/data \
    && chown -R node:node /app

USER node
EXPOSE 3500

ENTRYPOINT ["sh", "/app/docker-entrypoint.sh"]
CMD ["node", "server.js"]
