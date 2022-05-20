# Stage 1 - BUILD
FROM node:16-alpine as builder

ARG APP_NAME="your-service"
ARG APP_PATH="/opt"
ARG BASE_DIR="service"
ARG SOURCE="src"

RUN apk update          && \
    apk add --update       \
      bash                 \
      curl                 \
      git               && \
    # curl -sfL https://install.goreleaser.com/github.com/tj/node-prune.sh | bash -s -- -b /usr/local/bin   && \
    rm -rf /var/cache/apk/*

WORKDIR ${APP_PATH}/${APP_NAME}

COPY ${BASE_DIR}/package*.json ${BASE_DIR}/tsconfig.json ./

RUN npm ci

COPY ${BASE_DIR}/${SOURCE} ./${SOURCE}

RUN npm run build                                        && \
    npm prune --production                               && \
    # /usr/local/bin/node-prune                            && \
    find ./node_modules/ -name "*.map" -type f -delete   && \
    du -sh ./node_modules/* | sort -nr


# Stage 2 - Production

FROM alpine:3.15 as production

ARG APP_NAME="your-service"
ARG APP_PATH="/opt/"

WORKDIR ${APP_PATH}/${APP_NAME}

RUN apk add --update nodejs && \
    rm -rf /var/cache/apk/*

COPY package*.json ./
COPY --from=builder $APP_PATH/${APP_NAME}/node_modules ./node_modules
COPY --from=builder $APP_PATH/${APP_NAME}/dist ./

#EXPOSE 3000

CMD node index.js