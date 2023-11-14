.PHONY: docker-build
docker-build:
	docker build \
	--tag ghcr.io/caius/spacelift-tailscale:dev \
	.
