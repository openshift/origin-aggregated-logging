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

Use the script `hack/update-fluentd-vendor-gems.sh` to update the vendored source
code for Fluentd.  It is highly recommended to use something like [rvm](https://rvm.io) in order to isolate specific gem versions being used by Fluentd. 

**Note:** Be sure to add `fluentd/rh-manifest.txt`
or add it to the commit if it was updated.

### Add a new dependency or update a dependency version
1. Use a ruby version: `rvm use $RUBY-VERSION`
1. Create a gemset: `rvm gemset create $GEMSETNAME`
1. Use gemset: `rvm gemset use $GEMSETNAME`
1. Edit: `./fluentd/Gemfile`
1. Vendor dependencies: `./hack/update-fluentd-vendor-gems.sh`

### Updating all the dependencies

Follow the previous steps changing the task: `BUNDLE_TASK=update ./hack/update-fluentd-vendor-gems.sh`

### Tidying Vendor Directory
Set the clobber env var: `CLOBBER_VENDOR=true ./hack/update-fluentd-vendor-gems.sh`

### Updating jemalloc

Edit the file `fluentd/source.jemalloc` to also update the
vendored jemalloc source.  You will have to use `git add` or `git rm` or otherwise
fix any conflicts, then commit and submit a PR.  

