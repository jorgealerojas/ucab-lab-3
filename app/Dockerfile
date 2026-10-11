# syntax=docker/dockerfile:1
FROM node:22-alpine AS test
WORKDIR /workspace
COPY package.json ./
COPY src ./src
COPY test ./test
RUN npm test

FROM node:22-alpine AS runtime
ARG APP_VERSION=v1
ENV APP_VERSION=${APP_VERSION} \
    NODE_ENV=production \
    PORT=3000
WORKDIR /app
COPY --from=test --chown=node:node /workspace/package.json ./package.json
COPY --from=test --chown=node:node /workspace/src ./src
USER 1000:1000
EXPOSE 3000
HEALTHCHECK --interval=5s --timeout=2s --start-period=3s --retries=5 \
  CMD ["node", "-e", "require('node:http').get('http://127.0.0.1:3000/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"]
CMD ["node", "src/server.js"]
