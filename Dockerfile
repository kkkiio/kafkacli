FROM debian:12-slim AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG MOONBIT_VERSION=latest

ENV MOON_HOME=/root/.moon
ENV PATH=$MOON_HOME/bin:$PATH
ENV MB_ARCH=linux-x86_64
ENV TCCDIR=/usr/lib/x86_64-linux-gnu/tcc
ENV C_INCLUDE_PATH=/usr/lib/x86_64-linux-gnu/tcc/include

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates curl git xz-utils tar pkg-config tcc binutils \
  librdkafka-dev libssl-dev zlib1g-dev libzstd-dev liblz4-dev \
  && rm -rf /var/lib/apt/lists/*

# Install Moon toolchain (amd64 only) - split into steps for better caching
RUN mkdir -p "$MOON_HOME"
RUN curl --fail --location --progress-bar --output /tmp/moonbit.tgz "https://cli.moonbitlang.com/binaries/${MOONBIT_VERSION}/moonbit-${MB_ARCH}.tar.gz"
RUN tar -xzf /tmp/moonbit.tgz -C "$MOON_HOME" && rm -f /tmp/moonbit.tgz && chmod -R +x "$MOON_HOME/bin" || true
RUN mkdir -p "$MOON_HOME/lib"
RUN curl --fail --location --progress-bar --output /tmp/core.tgz "https://cli.moonbitlang.com/cores/core-${MOONBIT_VERSION}.tar.gz"
RUN tar -xzf /tmp/core.tgz -C "$MOON_HOME/lib" && rm -f /tmp/core.tgz

# Bundle core with -j 1 to avoid deadlocks
RUN moon bundle -j 1 --warn-list -a --all --source-dir "$MOON_HOME/lib/core"
RUN moon bundle -j 1 --warn-list -a --target wasm-gc --source-dir "$MOON_HOME/lib/core" --quiet

WORKDIR /app

# Copy project manifest after installing Moon (build cache friendly)
COPY moon.mod.json ./

# Resolve dependencies before building
RUN moon update

# Copy source and build with -j 1
COPY . .
RUN moon build -j 1

FROM debian:12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
  librdkafka1 libssl3 zlib1g libzstd1 liblz4-1 ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/native/release/build/main/main.exe /usr/local/bin/kafkacli

CMD ["kafkacli"]
