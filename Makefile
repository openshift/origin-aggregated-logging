OPERATOR_LOGGING_IMAGE_STREAM?=stable

FLUENTD_IMAGE?="openshift/origin-logging-fluentd"
KIBANA_IMAGE?="openshift/origin-logging-kibana5"
ELASTICSEARCH_IMAGE?="openshift/origin-logging-elasticsearch5"
CURATOR_IMAGE?="openshift/origin-logging-curator5"

# Build the Docker images for Origin Aggregated Logging
build-images:
	hack/build-images.sh
.PHONY: build-images

test:
	EXCLUDE_SUITE="json-parsing|upgrade|zzz-rsyslog|debug_level_logs|fluentd-forward|remote-syslog|out_rawtcp|zzz-duplicate-entries|read-throttling|viaq-data-model|zzzz-bulk-rejection" hack/testing/entrypoint.sh
.PHONY: test

test-upgrade:
	SUITE=test-upgrade hack/testing/entrypoint.sh
.PHONY: test-upgrade

test-pre-upgrade:
	SUITE=test-pre-upgrade hack/testing/entrypoint.sh
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
