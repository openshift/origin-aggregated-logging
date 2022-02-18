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

