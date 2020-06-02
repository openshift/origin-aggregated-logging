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
    CURATOR_TIMEOUT=300 \
    CURATOR_VER=5.8.1 \
    container=oci \
    LC_ALL=en_US.UTF-8 

LABEL io.k8s.description="Curator elasticsearch container for elasticsearch deletion/archival" \
  io.k8s.display-name="Curator ${CURATOR_VER}" \
  io.openshift.tags="logging,elk,elasticsearch,curator"

RUN yum install -y python3 && \
    yum clean all && \
    ln -sf /usr/bin/python3 /usr/bin/python

COPY . ${HOME}
RUN mkdir -p $(dirname "$CURATOR_CONF_LOCATION") && \
    touch ${CURATOR_CONF_LOCATION} && \
    chmod -R u+x ${HOME} && \
    chgrp -R 0 ${HOME} && \
    chmod -R g=u ${HOME}
WORKDIR ${HOME}/vendor
RUN pip3 install $(ls . | grep -v curator) -q --no-index --find-links . && \
    pip3 install elasticsearch-curator* --no-index -q && \
    rm -rf $HOME/vendor && \
    ls /usr/local/bin/curator

WORKDIR ${HOME}
USER 1001
CMD ["sh", "run.sh"]
