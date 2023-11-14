.PHONY: docker-build
docker-build:
	DOCKER_BUILDKIT=1 docker build \
	--tag ghcr.io/caius/spacelift-tailscale:dev \
	.
