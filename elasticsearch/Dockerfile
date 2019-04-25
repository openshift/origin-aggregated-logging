FROM elasticsearch:5.6.13

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 9200
EXPOSE 9300
USER 0

ENV ES_CONF=/etc/elasticsearch/ \
    ES_HOME=/usr/share/elasticsearch \
    ES_VER=5.6.13 \
    HOME=/opt/app-root/src \
    INSTANCE_RAM=512G \
    JAVA_VER=1.8.0 \
    NODE_QUORUM=1 \
    OSE_ES_VER=5.6.13.5-redhat-1 \
    PROMETHEUS_EXPORTER_VER=5.6.13.2-redhat-3 \
    PLUGIN_LOGLEVEL=INFO \
    RECOVER_AFTER_NODES=1 \
    RECOVER_EXPECTED_NODES=1 \
    RECOVER_AFTER_TIME=5m \
    RELEASE_STREAM=prod \
    DHE_TMP_KEY_SIZE=2048 \
    container=oci

ARG OSE_ES_VER=5.6.13.5-redhat-1
ARG OSE_ES_URL
ARG PROMETHEUS_EXPORTER_VER=5.6.13.2-redhat-3
ARG PROMETHEUS_EXPORTER_URL
ARG MAVEN_REPO_URL=http://download-node-02.eng.bos.redhat.com/brewroot/repos/lpc-rhel-7-maven-build/latest/maven/

ADD sgconfig/ ${HOME}/sgconfig/
ADD index_templates/ ${ES_HOME}/index_templates/
ADD index_patterns/ ${ES_HOME}/index_patterns/
ADD init/ ${ES_HOME}/init/
ADD kibana_ui_objects/ ${ES_HOME}/kibana_ui_objects/
ADD probe/ ${ES_HOME}/probe/
ADD init.sh run.sh prep-install.${RELEASE_STREAM} install.sh ${HOME}/
COPY utils/** /usr/local/bin/
RUN ln -s /usr/local/bin/logging ${HOME}/logging

RUN ${HOME}/install.sh

WORKDIR ${HOME}
USER 1000
CMD ["sh", "/opt/app-root/src/run.sh"]
