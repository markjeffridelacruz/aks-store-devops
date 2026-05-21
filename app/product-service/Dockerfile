# Stage 1 - Build
FROM rust:1.82 AS builder

WORKDIR /app

COPY . .

RUN cargo build --release

# Stage 2 - Runtime
FROM debian:bookworm-slim

WORKDIR /app

RUN apt-get update && apt-get install -y wget libssl-dev && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/product-service ./product-service

EXPOSE 3002

CMD ["./product-service"]