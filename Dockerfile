FROM golang:1.21-alpine AS build

RUN go install github.com/txn2/txeh/txeh@master

# hadolint ignore=DL3007
FROM ghcr.io/spacelift-io/runner-terraform:latest AS spacelift

USER root


# hadolint ignore=DL3018
RUN apk add --no-cache tailscale

# Let tailscale/d use default socket location
RUN mkdir -p /var/run/tailscale && chown spacelift:spacelift /var/run/tailscale

# Lets us easily add entries to /etc/hosts if we wish
COPY --from=build --chown=root:root /go/bin/txeh /usr/local/bin/
RUN chmod 4755 /usr/local/bin/txeh

COPY bin/ /usr/local/bin/

USER spacelift
