# Hacking on Origin Aggregated Logging

## Building on OpenShift

Use the script `hack/build-images.sh`.  It has options for building using `imagebuilder`
or `imagestreams/buildconfigs` with the [dev-builds template](hack/templates/dev-builds.yaml).
Using `imagebuilder` is the default and preferred method.  `hack/build-images.sh` knows
how to build images based on UBI.  If you use the `dev-builds template` you'll need an
OpenShift cluster.  Also if you want to push images into a cluster (as opposed to pushing
images into a public registry like `quay.io`).

## Deploying OpenShift

The script `hack/deploy-openshift-cluster.sh` can be used to deploy an OpenShift cluster.
You will need an AWS account with proper privileges and a pull secret.  See the file for
more details.

## Deploying Logging and Testing On OpenShift

The script `hack/get-cluster-run-tests.sh` will do all of the above plus deploy logging
using the built images plus launch the logging CI tests.  It also depends on the
[elasticsearch-operator](https://github.com/openshift/elasticsearch-operator) and the
[cluster-logging-operator](https://github.com/openshift/cluster-logging-operator), and
see the file `hack/get-cluster-run-tests.sh` for more information.

## Updating Sources for Fluentd

Use the script `hack/update-fluentd-vendor-gems.sh` to update the vendored source
code for Fluentd.  Edit the file `fluentd/source.jemalloc` to also update the
vendored jemalloc source.  You will have to use `git add` or `git rm` or otherwise
fix any conflicts, then commit and submit a PR.  Be sure to add `fluentd/rh-manifest.txt`
or add it to the commit if it was updated.

## Updating Sources for Rsyslog

Check the file `rsyslog/rsyslog_exporter.source` to see if there are any new releases
upstream, and update the file if so.
Update `rsyslog/go/src/github.com/soundcloud/rsyslog_exporter/Gopkg.toml` to
update any dependency versions if necessary before running the script below.
Use the script `hack/update-rsyslog-vendor-src.sh` to update the `rsyslog-vendor`
branch with the latest rsyslog sources, commit and push, then rebase or merge
those changes in with your feature branch which you intend to use to submit a PR.
Be sure to add `rsyslog/rh-manifest.txt` or add it to the commit if it was updated.
