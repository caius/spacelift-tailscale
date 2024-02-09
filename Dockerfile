# hadolint ignore=DL3007
FROM ghcr.io/spacelift-io/runner-terraform:latest AS spacelift

USER root

# hadolint ignore=DL3018
RUN apk add --no-cache tailscale

COPY bin/ /usr/local/bin/

# Let tailscale/d use default socket location
RUN mkdir -p /home/spacelift/.local/share/tailscale /var/run/tailscale && chown spacelift:spacelift /home/spacelift/.local/share/tailscale /var/run/tailscale

USER spacelift
