# Stage 1 - Build
FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY . .

RUN go mod download

RUN go build -o makeline-service .

# Stage 2 - Runtime
FROM alpine:latest

WORKDIR /app

COPY --from=builder /app/makeline-service .

EXPOSE 3001

CMD ["./makeline-service"]