# Build the Docker images for Origin Aggregated Logging
build-images:
	hack/build-images.sh
.PHONY: build-images

test:
	./openshift/ci-operator/build-image/setup-logging-for-e2e.sh
.PHONY: test

test-upgrade:
	./openshift/ci-operator/build-image/setup-logging-for-e2e.sh
.PHONY: test-upgrade

test-pre-upgrade:
	SUITE=test-pre-upgrade hack/testing/entrypoint.sh
.PHONY: test-pre-upgrade
