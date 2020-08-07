FROM ubi7:latest

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 9200
EXPOSE 9300
USER 0

ENV ES_PATH_CONF=/etc/elasticsearch/ \
    ES_HOME=/usr/share/elasticsearch \
    ES_VER=6.8.1.redhat-6 \
    HOME=/opt/app-root/src \
    INSTANCE_RAM=512G \
    JAVA_VER=1.8.0 \
    JAVA_HOME=/usr/lib/jvm/jre \
    NODE_QUORUM=1 \
    PROMETHEUS_EXPORTER_VER=6.8.1.0-redhat-1 \
    OPENDISTRO_VER=0.10.1.0-redhat-1 \
    PLUGIN_LOGLEVEL=INFO \
    RECOVER_AFTER_NODES=1 \
    RECOVER_EXPECTED_NODES=1 \
    RECOVER_AFTER_TIME=5m \
    DHE_TMP_KEY_SIZE=2048 \
    RELEASE_STREAM=origin

ARG MAVEN_REPO_URL=file:///artifacts/

RUN packages="java-${JAVA_VER}-openjdk-headless \
              PyYAML  \
              hostname \
              openssl \
              zip \
              unzip" && \
    yum install -y --setopt=tsflags=nodocs ${packages} && \
    rpm -V ${packages} && \
    yum clean all

ADD extra-jvm.options install-es.sh /var/tmp
COPY artifacts /artifacts
RUN /var/tmp/install-es.sh

ADD sgconfig/ ${HOME}/sgconfig/
ADD index_templates/ ${ES_HOME}/index_templates/
ADD index_patterns/ ${ES_HOME}/index_patterns/
ADD init/ ${ES_HOME}/init/
ADD probe/ ${ES_HOME}/probe/
ADD init.sh run.sh prep-install* install.sh ${HOME}/
COPY utils/** /usr/local/bin/

ARG PROMETHEUS_EXPORTER_URL=${MAVEN_REPO_URL}org/elasticsearch/plugin/prometheus/prometheus-exporter/${PROMETHEUS_EXPORTER_VER}/prometheus-exporter-${PROMETHEUS_EXPORTER_VER}.zip
ARG OPENDISTRO_URL=${MAVEN_REPO_URL}com/amazon/opendistroforelasticsearch/opendistro_security/${OPENDISTRO_VER}/opendistro_security-${OPENDISTRO_VER}.zip

RUN ${HOME}/install.sh && rm -rf /artifacts

WORKDIR ${HOME}
USER 1000
CMD ["sh", "/opt/app-root/src/run.sh"]
