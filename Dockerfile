# hadolint ignore=DL3007
FROM ghcr.io/spacelift-io/runner-terraform:latest AS spacelift

LABEL org.opencontainers.image.source=https://github.com/caius/spacelift-tailscale
LABEL org.opencontainers.image.description="Spacelift runner with Tailscale installed"

USER root

# hadolint ignore=DL3018
RUN apk add --no-cache tailscale

COPY bin/ /usr/local/bin/

USER spacelift
