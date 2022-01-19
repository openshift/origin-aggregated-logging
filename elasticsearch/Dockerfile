FROM rhel7:7-released

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 9200
EXPOSE 9300
USER 0

ENV ES_CONF=/etc/elasticsearch/ \
    ES_HOME=/usr/share/elasticsearch \
    ES_VER=5.6.16 \
    HOME=/opt/app-root/src \
    INSTANCE_RAM=512G \
    JAVA_VER=1.8.0 \
    NODE_QUORUM=1 \
    OSE_ES_VER=5.6.16.4-redhat-00001 \
    ES_VER_REDHAT=5.6.16.redhat-00004 \
    PROMETHEUS_EXPORTER_VER=5.6.16.0-redhat-1 \
    PLUGIN_LOGLEVEL=INFO \
    RECOVER_AFTER_NODES=1 \
    RECOVER_EXPECTED_NODES=1 \
    RECOVER_AFTER_TIME=5m \
    RELEASE_STREAM=prod \
    DHE_TMP_KEY_SIZE=2048 \
    container=oci

ARG ES_ARCHIVE_URL
ARG PROMETHEUS_EXPORTER_VER=5.6.16.0-redhat-1
ARG PROMETHEUS_EXPORTER_URL
ARG MAVEN_REPO_URL=file:///artifacts/

RUN yum-config-manager -q --enable rhel-7-server-extras-rpms && \
    packages="java-${JAVA_VER}-openjdk-headless \
              PyYAML  \
              hostname \
              openssl \
              zip \
              unzip" && \
    yum install -y --setopt=tsflags=nodocs ${packages} && \
    yum clean all

ADD extra-jvm.options ${ES_CONF}/
ADD sgconfig/ ${HOME}/sgconfig/
ADD index_templates/ ${ES_HOME}/index_templates/
ADD index_patterns/ ${ES_HOME}/index_patterns/
ADD init/ ${ES_HOME}/init/
ADD kibana_ui_objects/ ${ES_HOME}/kibana_ui_objects/
ADD probe/ ${ES_HOME}/probe/
ADD init.sh run.sh prep-install* install.sh ${HOME}/
COPY utils/** /usr/local/bin/
COPY artifacts /artifacts
RUN ln -s /usr/local/bin/logging ${HOME}/logging && \
    ${HOME}/install.sh && \ 
    rm -rf /artifacts

WORKDIR ${HOME}
USER 1000
CMD ["sh", "/opt/app-root/src/run.sh"]

LABEL \
        License="GPLv2+" \
        io.k8s.description="Elasticsearch container for EFK aggregated logging storage" \
        io.k8s.display-name="Elasticsearch 5" \
        io.openshift.tags="logging,elk,elasticsearch" \
        vendor="Red Hat" \
        name="openshift3/ose-logging-elasticsearch5" \
        com.redhat.component="logging-elasticsearch5-container" \
        io.openshift.maintainer.product="OpenShift Container Platform" \
        io.openshift.maintainer.component="Logging" \
        version="v3.11"
