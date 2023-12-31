# hadolint ignore=DL3007
FROM ghcr.io/spacelift-io/runner-terraform:latest AS spacelift

USER root

# hadolint ignore=DL3018
RUN apk add --no-cache tailscale

# Let tailscale/d use default socket location
RUN mkdir -p /var/run/tailscale && chown spacelift:spacelift /var/run/tailscale

COPY bin/ /usr/local/bin/

USER spacelift
