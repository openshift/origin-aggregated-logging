# Build the Docker images for Origin Aggregated Logging
build-images:
	hack/build-images.sh
.PHONY: build-images

test:
	hack/testing/entrypoint.sh
.PHONY: test