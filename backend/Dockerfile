FROM golang:1.19.2-alpine3.16 as builder
WORKDIR /usr/src
COPY . .
RUN go build ./cmd/api/

FROM golang:1.19.2-alpine3.16
WORKDIR /app
RUN addgroup --system goserv \
    && adduser -S -s /bin/false -G goserv goserv -D -H\
    && apk add --no-cache dumb-init
COPY --chown=goserv:goserv \
    --from=builder \
    /usr/src/api ./api
EXPOSE 8081
# приложение будет запускаться под пользователем goserv
USER goserv
ENTRYPOINT ["dumb-init", "./api"]
