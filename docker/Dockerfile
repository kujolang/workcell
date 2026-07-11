# Minimal local demonstration image. Build with:
# docker build --tag kujolang/workcell-base:local docker/
FROM alpine:3.20

LABEL org.opencontainers.image.title="Kujo Workcell base"
LABEL org.opencontainers.image.description="Minimal non-root image for local Workcell examples"

RUN addgroup -g 65532 workcell && adduser -D -u 65532 -G workcell workcell
WORKDIR /workspace
USER 65532:65532

CMD ["/bin/sh"]
