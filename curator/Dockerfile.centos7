FROM centos:centos7

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
    CURATOR_VER=5.2 \
    CURATOR_TIMEOUT=300

LABEL io.k8s.description="Curator elasticsearch container for elasticsearch deletion/archival" \
  io.k8s.display-name="Curator ${CURATOR_VER}" \
  io.openshift.tags="logging,elk,elasticsearch,curator"

ADD elasticsearch.repo /etc/yum.repos.d/
RUN yum install -y epel-release && \
    rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
RUN yum install -y --setopt=tsflags=nodocs \
        python-pip && \
    pip install --no-cache-dir 'pyyaml==3.12' 'ruamel.yaml<=0.15' elasticsearch-curator==${CURATOR_VER} && \
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
