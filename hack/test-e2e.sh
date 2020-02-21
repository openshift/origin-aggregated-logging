#!/bin/bash
set -euo pipefail
current_dir=$(dirname "${BASH_SOURCE[0]}" )
source $current_dir/testing/common
OPERATOR_LOGGING_IMAGE_STREAM=${OPERATOR_LOGGING_IMAGE_STREAM:-"stable"}


# disable pathname expansion for SUITE and EXCLUDE_SUITE
# e.g. .* will expand to . .. .gitignore .travis.yml
# we do not want that
set -f
# EXCLUDE_SUITE="${EXCLUDE_SUITE:-"$^"}"
INCLUDE_SUITE="test-010-*|multi-tenancy"
set +f
# log::info "Excluding tests: '${EXCLUDE_SUITE}'"
# for test in $( find "${current_dir}/testing" -type f -name 'test-*.sh' | grep -Ev "${EXCLUDE_SUITE}" | sort); do
for test in $( find "${current_dir}/testing" -type f -name 'test-*.sh' | grep -E "${INCLUDE_SUITE}" | sort); do
	log::info "==============================================================="
	log::info "running e2e $test "
	log::info "==============================================================="
	if "${test}" ; then
		log::info "==========================================================="
		log::info "e2e $test succeeded at $( date )"
		log::info "==========================================================="
	else
		log::error "============= FAILED FAILED ============= "
		log::error "e2e $test failed at $( date )"
		log::error "============= FAILED FAILED ============= "
		failed="true"
	fi
done

if [[ -n "${failed:-}" ]]; then
    exit 1
fi
