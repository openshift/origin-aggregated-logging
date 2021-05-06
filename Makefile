OPERATOR_LOGGING_IMAGE_STREAM?=stable

FLUENTD_IMAGE?="openshift/origin-logging-fluentd"
KIBANA_IMAGE?="openshift/origin-logging-kibana6"
ELASTICSEARCH_IMAGE?="openshift/origin-logging-elasticsearch6"
CURATOR_IMAGE?="openshift/origin-logging-curator5"

export LOGGING_VERSION=5.2

# Build the Docker images for Origin Aggregated Logging
build-images: build-all-images
.PHONY: build-images

test:
	OPERATOR_LOGGING_IMAGE_STREAM=$(OPERATOR_LOGGING_IMAGE_STREAM) ./hack/test-e2e.sh
.PHONY: test

.PHONY: test-pre-upgrade

build-fluentd-image:
	hack/build-component-image.sh "fluentd" $(FLUENTD_IMAGE)
.PHONY: build-fluentd-image

build-kibana-image:
	hack/build-component-image.sh "kibana" $(KIBANA_IMAGE)
.PHONY: build-kibana-image

build-elasticsearch-image:
	hack/build-component-image.sh "elasticsearch" $(ELASTICSEARCH_IMAGE)
.PHONY: build-elasticsearch-image

build-curator-image:
	hack/build-component-image.sh "curator" $(CURATOR_IMAGE)
.PHONY: build-curator-image

build-all-images: build-fluentd-image build-kibana-image build-elasticsearch-image build-curator-image
.PHONY: build-all-images

deploy-fluentd-image: build-fluentd-image
	hack/deploy-component-image.sh $(FLUENTD_IMAGE)
.PHONY: deploy-fluentd-image

deploy-kibana-image: build-kibana-image
	hack/deploy-component-image.sh $(KIBANA_IMAGE)
.PHONY: deploy-kibana-image

deploy-elasticsearch-image: build-elasticsearch-image
	hack/deploy-component-image.sh $(ELASTICSEARCH_IMAGE)
.PHONY: deploy-elasticsearch-image

deploy-curator-image: build-curator-image
	hack/deploy-component-image.sh $(CURATOR_IMAGE)
.PHONY: deploy-curator-image

deploy-all-images: deploy-fluentd-image deploy-kibana-image deploy-elasticsearch-image deploy-curator-image
.PHONY: deploy-all-images

lint:
	@hack/run-linter
.PHONY: lint

gen-dockerfiles:
	@for d in "curator" "elasticsearch" "fluentd" "kibana"; do  \
		./hack/generate-dockerfile-from-midstream "$$d/Dockerfile.in" > "$$d/Dockerfile" ; \
	done
.PHONY: gen-dockerfiles
