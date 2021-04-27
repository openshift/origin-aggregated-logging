# Hacking on Origin Aggregated Logging

## Building on OpenShift

Use the script `hack/build-images.sh`.  It has options for building using `imagebuilder`
or `imagestreams/buildconfigs` with the [dev-builds template](hack/templates/dev-builds.yaml).
Using `imagebuilder` is the default and preferred method.  `hack/build-images.sh` knows
how to build images based on UBI.  If you use the `dev-builds template` you'll need an
OpenShift cluster.  Also if you want to push images into a cluster (as opposed to pushing
images into a public registry like `quay.io`).

## Deploying to OpenShift

See the [cluster-logging-operator](https://github.com/openshift/cluster-logging-operator/blob/master/docs/HACKING.md) hacking document for deploying OpenShift Logging using the operator make targets.

## Updating Sources for Fluentd

	See [fluentd/README.md](fluentd/README.md)

### Updating all the dependencies

Follow the previous steps changing the task: `BUNDLE_TASK=update ./hack/update-fluentd-vendor-gems.sh`

### Tidying Vendor Directory
Set the clobber env var: `CLOBBER_VENDOR=true ./hack/update-fluentd-vendor-gems.sh`

### Updating jemalloc

 Edit the file `fluentd/source.jemalloc` to also update the
vendored jemalloc source.  You will have to use `git add` or `git rm` or otherwise
fix any conflicts, then commit and submit a PR.
