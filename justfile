build:
  moon build --release --target native
build-amd64-image:
  docker build --platform linux/amd64 -t kkkiio/kafkacli:latest .