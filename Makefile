# Build the Docker images for Origin Aggregated Logging
build-images:
	hack/build-images.sh
.PHONY: build-images

test:
	EXCLUDE_SUITE="upgrade|test-curator" hack/testing/entrypoint.sh
.PHONY: test

test-upgrade:
	SUITE=test-upgrade hack/testing/entrypoint.sh
.PHONY: test-upgrade

test-pre-upgrade:
	SUITE=test-pre-upgrade hack/testing/entrypoint.sh
.PHONY: test-pre-upgrade
