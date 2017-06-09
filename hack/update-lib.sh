#!/bin/bash

# This script attempts to update the vendored
# copy of hack/lib from Origin and re-apply all
# the [carry] commits on top.

for sha in $( git log --pretty='%H' -- hack/lib/ ); do
	subject="$( git log -n 1 --pretty='%s' "${sha}" )"
	if [[ "${subject}" =~ ^"Vendor origin/hack/lib at "([0-9a-z]+) ]]; then
		last_vendor_commit="${sha}"
		last_origin_commit="${BASH_REMATCH[1]}"
		break
	fi
done

carry_commits=()
for sha in $( git log --reverse --pretty='%H' "${last_vendor_commit}..HEAD" -- hack/lib ); do
	subject="$( git log -n 1 --pretty='%s' "${sha}" )"
	if [[ "${subject}" =~ ^"[carry]"* ]]; then
		carry_commits+=( "${sha}" )
	fi
done

origin_tmp="$( mktemp -d )"
git clone git@github.com:openshift/origin.git "${origin_tmp}"
pushd "${origin_tmp}"
origin_head="$( git log -n 1 --pretty=%h )"
changelog="$( git log --pretty='%h %s' "${last_origin_commit}..HEAD" --no-merges -- hack/lib )"
popd

rm -rf hack/lib
cp -r "${origin_tmp}/hack/lib" hack/
rm -rf "${origin_tmp}"
git add hack/lib
git commit --message "Vendor origin/hack/lib at ${origin_head}

Changelog:
${changelog}"

for commit in "${carry_commits[@]}"; do
	git cherry-pick "${commit}"
done
