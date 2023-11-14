FROM ghcr.io/spacelift-io/runner-terraform:latest AS spacelift

LABEL org.opencontainers.image.source=https://github.com/caius/spacelift-tailscale
LABEL org.opencontainers.image.description="Spacelift runner with Tailscale"
