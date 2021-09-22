### This is a generated file from Dockerfile.in ###

#@follow_tag(registry.redhat.io/ubi8/python-36:latest)
FROM registry.ci.openshift.org/ocp/builder:ubi8.python.36


ENV BUILD_VERSION=5.8.1
ENV SOURCE_GIT_COMMIT=${CI_ORIGIN_AGGREGATED_LOGGING_UPSTREAM_COMMIT:-}
ENV SOURCE_GIT_URL=${CI_ORIGIN_AGGREGATED_LOGGING_UPSTREAM_URL:-}

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

ENV HOME=/opt/app-root/src \
    ES_HOST=localhost \
    ES_PORT=9200 \
    ES_CA=/etc/curator/keys/ca \
    ES_CLIENT_CERT=/etc/curator/keys/cert \
    ES_CLIENT_KEY=/etc/curator/keys/key \
    CURATOR_CONF_LOCATION=/etc/curator/settings/config.yaml \
    CURATOR_CONF_FILE=/etc/curator/settings/curator5.yaml \
    CURATOR_ACTIONS_FILE=/etc/curator/settings/actions.yaml \
    CURATOR_LOG_LEVEL=ERROR \
    CURATOR_SCRIPT_LOG_LEVEL=INFO \
    CURATOR_TIMEOUT=300 \
    CURATOR_VER=5.8.1 \
    container=oci \
    LC_ALL=en_US.UTF-8
ENV upstream_code=${upstream_code:-"."}

USER 0
COPY  ${upstream_code}/ ${HOME}

RUN mkdir -p $(dirname "$CURATOR_CONF_LOCATION") && \
    touch ${CURATOR_CONF_LOCATION} && \
    chmod -R u+x ${HOME} && \
    chgrp -R 0 ${HOME} && \
    chmod -R g=u ${HOME}

WORKDIR ${HOME}/vendor
RUN pip install $(ls . | grep -v curator) -q --no-index --find-links . && \
    pip install elasticsearch-curator* --no-index -q && \
    rm -rf $HOME/vendor

WORKDIR ${HOME}
USER 1001
CMD ["sh", "run.sh"]

LABEL \
        License="Apache-2.0" \
        io.k8s.description="Curator elasticsearch container for elasticsearch deletion/archival" \
        io.k8s.display-name="Curator 5" \
        io.openshift.tags="logging,elk,elasticsearch,curator" \
        vendor="Red Hat" \
        name="openshift-logging/logging-curator5-rhel8" \
        com.redhat.component="logging-curator5-container" \
        io.openshift.maintainer.product="OpenShift Container Platform" \
        io.openshift.build.commit.id=${CI_ORIGIN_AGGREGATED_LOGGING_UPSTREAM_COMMIT} \
        io.openshift.build.source-location=${CI_ORIGIN_AGGREGATED_LOGGING_UPSTREAM_URL} \
        io.openshift.build.commit.url=${CI_ORIGIN_AGGREGATED_LOGGING_UPSTREAM_URL}/commit/${CI_ORIGIN_AGGREGATED_LOGGING_UPSTREAM_URL} \
        version=v5.8.1

