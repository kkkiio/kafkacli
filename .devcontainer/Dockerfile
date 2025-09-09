# FROM --platform=linux/amd64 debian:12
FROM --platform=linux/amd64 mcr.microsoft.com/devcontainers/base:bookworm


RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential pkg-config curl ca-certificates \
    librdkafka-dev libssl-dev zlib1g-dev libzstd-dev liblz4-dev