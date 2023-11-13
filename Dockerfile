FROM ghcr.io/spacelift-io/runner-terraform:latest AS spacelift

LABEL org.opencontainers.image.source=https://github.com/caius/spacelift-tailscale
LABEL org.opencontainers.image.description="Spacelift runner with Tailscale installed"

ARG TAILSCALE_VERSION=1.52.1

USER root

RUN mkdir -p /tmp/tailscale && \
  curl --fail --silent --show-error --location \
  "https://pkgs.tailscale.com/stable/tailscale_${TAILSCALE_VERSION}_amd64.tgz" \
  | tar -xz -C /tmp/tailscale --strip-components=1 -f - && \
  mv /tmp/tailscale/tailscale /usr/local/bin/tailscale && \
  mv /tmp/tailscale/tailscaled /usr/local/bin/tailscaled && \
  rm -rf /tmp/tailscale

USER spacelift
