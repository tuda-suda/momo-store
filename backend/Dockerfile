FROM golang:1.17-alpine
WORKDIR /usr/src
COPY . .
RUN go build ./cmd/api/

FROM golang:1.17-alpine
WORKDIR /app
RUN addgroup --system goserv \
    && adduser --system --shell /bin/false --disabled-login --ingroup goserv goserv \
    && apt update && apt install -y dumb-init curl && apt clean
COPY --chown=goserv:goserv \
    --from=builder \
    /usr/src/api ./api
EXPOSE 8081
# приложение будет запускаться под пользователем goserv
USER goserv
ENTRYPOINT ["dumb-init", "./api"]
