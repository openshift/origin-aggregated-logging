#!/bin/bash

# This library holds utility functions for determining
# product versions from Git repository state.

# os::build::version::get_vars loads the standard version variables as
# ENV vars
function os::build::version::get_vars() {
	if [[ -n "${OS_VERSION_FILE-}" ]]; then
		if [[ -f "${OS_VERSION_FILE}" ]]; then
			source "${OS_VERSION_FILE}"
			return
		fi
		if [[ ! -d "${OS_ROOT}/.git" ]]; then
			os::log::fatal "No version file at ${OS_VERSION_FILE}"
		fi
		os::log::warning "No version file at ${OS_VERSION_FILE}, falling back to git versions"
	fi
	os::build::version::openshift_vars
	os::build::version::kubernetes_vars
	os::build::version::etcd_vars
}
readonly -f os::build::version::get_vars

# os::build::version::openshift_vars looks up the current Git vars
function os::build::version::openshift_vars() {
	local git=(git --work-tree "${OS_ROOT}")

	if [[ -z "${OS_GIT_CATALOG_VERSION:-}" ]]; then
		# search git merge commits for template text and extract version
		# subject template: Merge version v0.0.14 of Service Catalog from https://github.com/openshift/service-catalog:v0.0.14+origin
		summary_text="$(${git[@]} log --merges --grep "Merge version v.* of Service Catalog from https://github.com/openshift/service-catalog" --pretty=%s -1)"
		if [[ "${summary_text}" =~ Merge[[:space:]]version[[:space:]](v.*)[[:space:]]of[[:space:]]Service[[:space:]]Catalog ]]; then
			OS_GIT_CATALOG_VERSION="${BASH_REMATCH[1]}"
		else
			os::log::fatal "Unable to find version for service catalog - (this should never happen)"
		fi

		if git_status=$("${git[@]}" status --porcelain cmd/service-catalog 2>/dev/null) && [[ -n ${git_status} ]]; then
			OS_GIT_CATALOG_VERSION+="dirty"
		fi
	fi

	if [[ -n ${OS_GIT_COMMIT-} ]] || OS_GIT_COMMIT=$("${git[@]}" rev-parse --short "HEAD^{commit}" 2>/dev/null); then
		if [[ -z ${OS_GIT_TREE_STATE-} ]]; then
			# Check if the tree is dirty.  default to dirty
			if git_status=$("${git[@]}" status --porcelain 2>/dev/null) && [[ -z ${git_status} ]]; then
				OS_GIT_TREE_STATE="clean"
			else
				OS_GIT_TREE_STATE="dirty"
			fi
		fi
		# Use git describe to find the version based on annotated tags.
		if [[ -n ${OS_GIT_VERSION-} ]] || OS_GIT_VERSION=$("${git[@]}" describe --long --tags --abbrev=7 --match 'v[0-9]*' "${OS_GIT_COMMIT}^{commit}" 2>/dev/null); then
			# Try to match the "git describe" output to a regex to try to extract
			# the "major" and "minor" versions and whether this is the exact tagged
			# version or whether the tree is between two tagged versions.
			if [[ "${OS_GIT_VERSION}" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)(\.[0-9]+)*([-].*)?$ ]]; then
				OS_GIT_MAJOR=${BASH_REMATCH[1]}
				OS_GIT_MINOR=${BASH_REMATCH[2]}
				OS_GIT_PATCH=${BASH_REMATCH[3]}
				if [[ -n "${BASH_REMATCH[5]}" ]]; then
					OS_GIT_MINOR+="+"
				fi
			fi

			# This translates the "git describe" to an actual semver.org
			# compatible semantic version that looks something like this:
			#   v1.1.0-alpha.0.6+84c76d1-345
			OS_GIT_VERSION=$(echo "${OS_GIT_VERSION}" | sed "s/-\([0-9]\{1,\}\)-g\([0-9a-f]\{7,40\}\)$/\+\2-\1/")
			# If this is an exact tag, remove the last segment.
			OS_GIT_VERSION=$(echo "${OS_GIT_VERSION}" | sed "s/-0$//")
			if [[ "${OS_GIT_TREE_STATE}" == "dirty" ]]; then
				# git describe --dirty only considers changes to existing files, but
				# that is problematic since new untracked .go files affect the build,
				# so use our idea of "dirty" from git status instead.
				OS_GIT_VERSION+="-dirty"
			fi
		fi
	fi
}
readonly -f os::build::version::openshift_vars

function os::build::version::etcd_vars() {
	ETCD_GIT_VERSION=$(go run "${OS_ROOT}/tools/godepversion/godepversion.go" "${OS_ROOT}/Godeps/Godeps.json" "github.com/coreos/etcd/etcdserver" "comment")
	ETCD_GIT_COMMIT=$(go run "${OS_ROOT}/tools/godepversion/godepversion.go" "${OS_ROOT}/Godeps/Godeps.json" "github.com/coreos/etcd/etcdserver")
}
readonly -f os::build::version::etcd_vars

# os::build::version::kubernetes_vars returns the version of Kubernetes we have
# vendored.
function os::build::version::kubernetes_vars() {
	KUBE_GIT_VERSION=$(go run "${OS_ROOT}/tools/godepversion/godepversion.go" "${OS_ROOT}/Godeps/Godeps.json" "k8s.io/kubernetes/pkg/api" "comment")
	KUBE_GIT_COMMIT=$(go run "${OS_ROOT}/tools/godepversion/godepversion.go" "${OS_ROOT}/Godeps/Godeps.json" "k8s.io/kubernetes/pkg/api")

	# This translates the "git describe" to an actual semver.org
	# compatible semantic version that looks something like this:
	#   v1.1.0-alpha.0.6+84c76d1142ea4d
	#
	# TODO: We continue calling this "git version" because so many
	# downstream consumers are expecting it there.
	KUBE_GIT_VERSION=$(echo "${KUBE_GIT_VERSION}" | sed "s/-\([0-9]\{1,\}\)-g\([0-9a-f]\{7,40\}\)$/\+\2/")

	# Try to match the "git describe" output to a regex to try to extract
	# the "major" and "minor" versions and whether this is the exact tagged
	# version or whether the tree is between two tagged versions.
	if [[ "${KUBE_GIT_VERSION}" =~ ^v([0-9]+)\.([0-9]+)(\.[0-9]+)*([-].*)?$ ]]; then
		KUBE_GIT_MAJOR=${BASH_REMATCH[1]}
		KUBE_GIT_MINOR=${BASH_REMATCH[2]}
		if [[ -n "${BASH_REMATCH[4]}" ]]; then
			KUBE_GIT_MINOR+="+"
		fi
	fi
}
readonly -f os::build::version::kubernetes_vars

# Saves the environment flags to $1
function os::build::version::save_vars() {
	local version_file=${1-}
	if [[ -z ${version_file} ]]; then
		os::log::fatal "No file specified as an argument to os::build::version::save_vars"
	fi

	cat <<EOF >"${version_file}"
OS_GIT_COMMIT='${OS_GIT_COMMIT-}'
OS_GIT_TREE_STATE='${OS_GIT_TREE_STATE-}'
OS_GIT_VERSION='${OS_GIT_VERSION-}'
OS_GIT_MAJOR='${OS_GIT_MAJOR-}'
OS_GIT_MINOR='${OS_GIT_MINOR-}'
OS_GIT_PATCH='${OS_GIT_PATCH-}'
KUBE_GIT_COMMIT='${KUBE_GIT_COMMIT-}'
KUBE_GIT_VERSION='${KUBE_GIT_VERSION-}'
ETCD_GIT_VERSION='${ETCD_GIT_VERSION-}'
ETCD_GIT_COMMIT='${ETCD_GIT_COMMIT-}'
EOF
}
readonly -f os::build::version::save_vars
