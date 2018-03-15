FROM rhel7.3:7.3-released

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
  io.openshift.tags="logging,elk,elasticsearch,curator" \
  com.redhat.component=logging-curator-docker \
  name="openshift3/logging-curator" \
  version="3.9.0" \
  release="1" \
  architecture=x86_64

RUN yum-config-manager --enable rhel-7-server-ose-3.6-rpms \
                       --enable rhel-7-server-extras-rpms && \
    INSTALL_PKGS="elastic-curator-${CURATOR_VER}.el7 \
                  PyYAML \
                  python-crontab \
                  python-setuptools \
                  pytz \
                  python-ruamel-yaml" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
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
