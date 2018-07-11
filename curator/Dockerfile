#oit## This file is managed by the OpenShift Image Tool: https://github.com/openshift/enterprise-images
#oit## by the OpenShift Continuous Delivery team (#aos-cd-team on IRC).
#oit## 
#oit## Any yum repos listed in this file will effectively be ignored during CD builds.
#oit## Yum repos must be enabled in the oit configuration files.
#oit## The content of this file is managed from an external source.
#oit## Changes made directly in distgit will be lost during the next
#oit## reconciliation process.
#oit## 
FROM rhel7:7-released

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
    CURATOR_VER=5.2.0 \
    CURATOR_TIMEOUT=300

ARG LOCAL_REPO
RUN if [ -n "${LOCAL_REPO}" ] ; then \
     curl -s -o /etc/yum.repos.d/local.repo ${LOCAL_REPO} ; \
    fi

RUN INSTALL_PKGS="elastic-curator-${CURATOR_VER} \
                  python2-ruamel-yaml" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V ${INSTALL_PKGS} && \
    yum clean all

COPY run.sh lib/oalconverter/* ${HOME}/

RUN mkdir -p $(dirname "$CURATOR_CONF_LOCATION") && \
    touch ${CURATOR_CONF_LOCATION} && \
    chmod -R u+x ${HOME} && \
    chgrp -R 0 ${HOME} && \
    chmod -R g=u ${HOME}

WORKDIR ${HOME}
USER 1001
CMD ["sh", "run.sh"]

LABEL \
        io.k8s.description="Curator elasticsearch container for elasticsearch deletion/archival" \
        com.redhat.component="logging-curator5-container" \
        vendor="Red Hat" \
        name="openshift3/ose-logging-curator5" \
        License="GPLv2+" \
        io.k8s.display-name="Curator 5" \
        version="v3.11.0" \
        architecture="x86_64" \
        release="1" \
        io.openshift.tags="logging,elk,elasticsearch,curator"

