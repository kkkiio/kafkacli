# Builder stage: Build the application
FROM debian:12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
  librdkafka1 libssl3 zlib1g libzstd1 liblz4-1 ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Copy prebuilt binary from host (built inside devcontainer)
COPY target/native/release/build/main/main.exe /usr/local/bin/kafkacli

CMD ["kafkacli"]
