# Hacking on Origin Aggregated Logging

## Building on OpenShift
Choose the project you want to hold your logging infrastructure.

Instantiate the [dev-builds template](hack/templates/dev-builds.yaml)
to define BuildConfigs.  The template has parameters to specify the repository and branch to use
for the builds. The defaults are for origin master. To develop your own
images, you can specify your own repos and branches as needed.

A word about the openshift-auth-proxy: it depends on the "node" base
image, which is intended to be the DockerHub nodejs base image. If you
have defined all the standard templates, they include a nodejs builder image
that is also called "node", and this will be used instead of the intended
base image, causing the build to fail. You can delete it to resolve this
problem:

```
    oc delete is/node -n openshift
```

The builds should start once defined; if any fail, you can retry them with:

```
    oc start-build <component>
```

e.g.

```
    oc start-build openshift-auth-proxy
```

This will start the builds in the background. Use oc logs -f build/<component> to 
follow the build logs, or use oc start-build --follow <component> to run the build 
in the foreground and follow the build logs.

In order to run a deployment with these images, you would process the
[deployer template](deployer/deployer.yaml) with the `IMAGE_PREFIX`
parameter pointing to the cluster registry location (e.g `IMAGE_PREFIX=172.30.90.128:5000/logs/`).

## Building locally

The images can also be built locally by executing the following in the root
directory of this repo:

```
    $PREFIX=docker.io/mynamespace/myloggingprefix- $OS_TAG=v1.x make
```

## Running the deployer script locally

When developing the deployer, it is fairly tedious to rebuild the image
and redeploy it just for tiny iterative changes.  The deployer script
is designed to be run either in the deployer image or directly. It
requires the openshift and oc binaries as well as the Java 8 JDK. When
run directly, it will use your current client context to create all
the objects, but you must still specify at least the PROJECT env var in
order to create everything with the right parameters. E.g.:

    cd deployer
    PROJECT=logging ./run.sh

There are a number of env vars this script looks at which are useful
when running directly; check the script headers for details.
