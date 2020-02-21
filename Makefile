OPERATOR_LOGGING_IMAGE_STREAM?=stable
# Build the Docker images for Origin Aggregated Logging
build-images:
	hack/build-images.sh
.PHONY: build-images

test:
	OPERATOR_LOGGING_IMAGE_STREAM=$(OPERATOR_LOGGING_IMAGE_STREAM) ./hack/test-e2e.sh
.PHONY: test

.PHONY: test-pre-upgrade
