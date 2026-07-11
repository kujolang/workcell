# Pinned Kujo tool image for the project-check example.
FROM rust:1.96.0-alpine3.22 AS builder

ARG KUJO_COMMIT=48b677e8e999161a348c06cfbc7761dc52b2e5e0

RUN apk add --no-cache git musl-dev openssl-dev pkgconfig
RUN git clone https://github.com/kujolang/kujo.git /src/kujo \
    && cd /src/kujo \
    && git checkout "$KUJO_COMMIT" \
    && cargo build --release --locked

FROM alpine:3.22

LABEL org.opencontainers.image.title="Kujo Workcell check image"
LABEL org.opencontainers.image.description="Pinned Kujo runtime for the Workcell project-check example"

RUN addgroup -g 65532 workcell && adduser -D -u 65532 -G workcell workcell
COPY --from=builder /src/kujo/target/release/kujo /usr/local/bin/kujo
WORKDIR /workspace
USER 65532:65532
CMD ["kujo", "--version"]
