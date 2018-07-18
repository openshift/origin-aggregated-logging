FROM rhel7:7-released

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 9200
EXPOSE 9300
USER 0

ENV ES_CONF=/etc/elasticsearch/ \
    ES_HOME=/usr/share/elasticsearch \
    ES_VER=5.6.10 \
    HOME=/opt/app-root/src \
    INSTANCE_RAM=512G \
    JAVA_VER=1.8.0 \
    NODE_QUORUM=1 \
    OSE_ES_VER=5.6.10.1 \
    PROMETHEUS_EXPORTER_VER=5.6.10.0 \
    PLUGIN_LOGLEVEL=INFO \
    RECOVER_AFTER_NODES=1 \
    RECOVER_EXPECTED_NODES=1 \
    RECOVER_AFTER_TIME=5m \
    RELEASE_STREAM=prod \
    container=oci

ARG OSE_ES_VER=5.6.10.1
ARG OSE_ES_URL
ARG PROMETHEUS_EXPORTER_VER=5.6.10.0
ARG PROMETHEUS_EXPORTER_URL

ADD sgconfig/ ${HOME}/sgconfig/
ADD index_templates/ ${ES_HOME}/index_templates/
ADD index_patterns/ ${ES_HOME}/index_patterns/
ADD kibana_ui_objects/ ${ES_HOME}/kibana_ui_objects/
ADD probe/ ${ES_HOME}/probe/
ADD run.sh prep-install.${RELEASE_STREAM} install.sh ${HOME}/
COPY utils/** /usr/local/bin/
RUN ln -s /usr/local/bin/logging ${HOME}/logging

RUN ${HOME}/install.sh

WORKDIR ${HOME}
USER 1000
CMD ["sh", "/opt/app-root/src/run.sh"]
