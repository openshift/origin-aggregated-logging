FROM rhel7:7-released

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 9200
EXPOSE 9300
USER 0

ENV ES_CLOUD_K8S_VER=2.4.4.01 \
    ES_CONF=/usr/share/java/elasticsearch/config \
    ES_JAVA_OPTS="-Dmapper.allow_dots_in_name=true" \
    ES_HOME=/usr/share/java/elasticsearch \
    ES_VER=2.4.4 \
    HOME=/opt/app-root/src \
    INSTANCE_RAM=512G \
    JAVA_VER=1.8.0 \
    NODE_QUORUM=1 \
    OSE_ES_VER=2.4.4.23 \
    PROMETHEUS_EXPORTER_VER=2.4.4.1 \
    PLUGIN_LOGLEVEL=INFO \
    RECOVER_AFTER_NODES=1 \
    RECOVER_EXPECTED_NODES=1 \
    RECOVER_AFTER_TIME=5m \
    RELEASE_STREAM=prod \
    DHE_TMP_KEY_SIZE=2048

ARG ES_CLOUD_K8S_VER=2.4.4.01
ARG OSE_ES_VER=2.4.4.23
ARG ES_CLOUD_K8S_URL
ARG OSE_ES_URL
ARG PROMETHEUS_EXPORTER_URL

RUN  packages="elasticsearch-${ES_VER} \
              elasticsearch-cloud-kubernetes \
              java-${JAVA_VER}-openjdk-headless \
              openshift-elasticsearch-plugin \
              PyYAML  \
              zip" && \
    yum install -y --setopt=tsflags=nodocs ${packages} && \
    yum clean all


ADD sgconfig/ ${HOME}/sgconfig/
ADD index_templates/ ${ES_HOME}/index_templates/
ADD index_patterns/ ${ES_HOME}/index_patterns/
ADD kibana_ui_objects/ ${ES_HOME}/kibana_ui_objects/
ADD probe/ ${ES_HOME}/probe/
ADD lib/ /tmp/lib/
ADD run.sh prep-install.${RELEASE_STREAM} install.sh ${HOME}/
COPY utils/** /usr/local/bin/
RUN ln -s /usr/local/bin/logging ${HOME}/logging

RUN ${HOME}/install.sh
RUN rm -rf /tmp/lib

WORKDIR ${HOME}
USER 1000
CMD ["sh", "/opt/app-root/src/run.sh"]

LABEL \
        io.k8s.description="Elasticsearch container for EFK aggregated logging storage" \
        com.redhat.component="logging-elasticsearch-container" \
        vendor="Red Hat" \
        name="openshift3/logging-elasticsearch" \
        License="GPLv2+" \
        io.k8s.display-name="Elasticsearch 2.4.4" \
        version="v3.9.27" \
        architecture="x86_64" \
        io.openshift.expose-services="9200:https, 9300:https" \
        io.openshift.tags="logging,elk,elasticsearch"
