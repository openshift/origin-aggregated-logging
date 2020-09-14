See Dockerfile.rhel8 for where this directory is copied into the
image during a build. During an OSBS build, this directory will
be populated from artifacts from within the Red Hat firewall.
During a CI build, this is directory will not be used at all, but
the Dockerfile still needs succeed in it's COPY statement.

