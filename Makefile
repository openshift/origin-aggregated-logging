# Build the Docker images for Origin Aggregated Logging
build-images:
	hack/build-images.sh
.PHONY: build-images

# HACK - excluding the following additional tests that rely on dependencies that is no longer possible with operators or 
# moved into the elasticsearch-proxy. Will need to be re-enabled:
#   check-logs - portions of the metrics parts disabled
#   test-access-control - missing plugin / dynamic bits
#   test-es-metrics-access - missing plugin handling of SAR
#   test-json-parsing - fluent start/stop - operator overrides "start/stop"
#   test-multi-tenancy - missing plugin / dynamic bits
test:
	OPERATOR_LOGGING_IMAGE_STREAM=feature-es6x EXCLUDE_SUITE="access-control|es-metrics|json-parsing|multi-tenancy|utf8-characters|check-logs|upgrade|zzz-rsyslog|debug_level_logs|fluentd-forward|remote-syslog|out_rawtcp|zzz-duplicate-entries|read-throttling|viaq-data-model|zzzz-bulk-rejection" hack/testing/entrypoint.sh
.PHONY: test

test-upgrade:
	OPERATOR_LOGGING_IMAGE_STREAM=feature-es6x SUITE=test-upgrade hack/testing/entrypoint.sh
.PHONY: test-upgrade

test-pre-upgrade:
	SUITE=test-pre-upgrade hack/testing/entrypoint.sh
.PHONY: test-pre-upgrade
