FROM centos:centos7

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
    JAVA_HOME=/usr/lib/jvm/jre \
    NODE_QUORUM=1 \
    OSE_ES_VER=5.6.13.5 \
    PROMETHEUS_EXPORTER_VER=5.6.13.2 \
    PLUGIN_LOGLEVEL=INFO \
    RECOVER_AFTER_NODES=1 \
    RECOVER_EXPECTED_NODES=1 \
    RECOVER_AFTER_TIME=5m \
    DHE_TMP_KEY_SIZE=2048 \
    RELEASE_STREAM=origin

ARG OSE_ES_VER=5.6.13.5
ARG SG_VER=5.6.13-19.2

LABEL io.k8s.description="Elasticsearch container for EFK aggregated logging storage" \
      io.k8s.display-name="Elasticsearch ${ES_VER}" \
      io.openshift.expose-services="9200:https, 9300:https" \
      io.openshift.tags="logging,elk,elasticsearch" \
      architecture=x86_64 \
      name="openshift3/logging-elasticsearch"

ADD elasticsearch.repo /etc/yum.repos.d/elasticsearch.repo
# install the RPMs in a separate step so it can be cached
RUN rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch && \
    yum install -y --setopt=tsflags=nodocs --nogpgcheck \
                java-${JAVA_VER}-openjdk-headless \
                elasticsearch-${ES_VER} \
                openssl \
                PyYAML && \
    yum clean all

ADD sgconfig/ ${HOME}/sgconfig/
ADD index_templates/ ${ES_HOME}/index_templates/
ADD index_patterns/ ${ES_HOME}/index_patterns/
ADD init/ ${ES_HOME}/init/
ADD kibana_ui_objects/ ${ES_HOME}/kibana_ui_objects/
ADD probe/ ${ES_HOME}/probe/
ADD init.sh run.sh prep-install.${RELEASE_STREAM} install.sh ${HOME}/
COPY utils/** /usr/local/bin/

ARG OSE_ES_URL
ARG PROMETHEUS_EXPORTER_URL=https://github.com/lukas-vlcek/elasticsearch-prometheus-exporter/releases/download/${PROMETHEUS_EXPORTER_VER}/prometheus-exporter-${PROMETHEUS_EXPORTER_VER}.zip
ARG SG_URL

RUN ln -s /usr/local/bin/logging ${HOME}/logging && \
    ${HOME}/install.sh && \
    rm -rf /tmp/lib

WORKDIR ${HOME}
USER 1000
CMD ["sh", "/opt/app-root/src/run.sh"]
