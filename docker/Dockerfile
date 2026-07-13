# Minimal local demonstration image. Build with:
# docker build --tag kujolang/workcell-base:local docker/
FROM alpine:3.20@sha256:d9e853e87e55526f6b2917df91a2115c36dd7c696a35be12163d44e6e2a4b6bc

LABEL org.opencontainers.image.title="Kujo Workcell base"
LABEL org.opencontainers.image.description="Minimal non-root image for local Workcell examples"

RUN addgroup -g 65532 workcell && adduser -D -u 65532 -G workcell workcell
WORKDIR /workspace
USER 65532:65532

CMD ["/bin/sh"]
