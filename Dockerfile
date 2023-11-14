# hadolint ignore=DL3007
FROM ghcr.io/spacelift-io/runner-terraform:latest AS spacelift

USER root

# hadolint ignore=DL3018
RUN apk add --no-cache tailscale

COPY bin/ /usr/local/bin/

USER spacelift
