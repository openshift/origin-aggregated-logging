FROM rhel7.3:7.3-released

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
    OSE_ES_VER=2.4.4.15 \
    PROMETHEUS_EXPORTER_VER=2.4.4.0 \
    PLUGIN_LOGLEVEL=INFO \
    RECOVER_AFTER_NODES=1 \
    RECOVER_EXPECTED_NODES=1 \
    RECOVER_AFTER_TIME=5m \
    RELEASE_STREAM=prod

ARG ES_CLOUD_K8S_VER=2.4.4.01
ARG OSE_ES_VER=2.4.4.15
ARG ES_CLOUD_K8S_URL
ARG OSE_ES_URL
ARG PROMETHEUS_EXPORTER_URL

LABEL io.k8s.description="Elasticsearch container for EFK aggregated logging storage" \
      io.k8s.display-name="Elasticsearch ${ES_VER}" \
      io.openshift.expose-services="9200:https, 9300:https" \
      io.openshift.tags="logging,elk,elasticsearch" \
      com.redhat.component=logging-elasticsearch-docker \
      architecture=x86_64 \
      name="openshift3/logging-elasticsearch" \
      version="v3.7.0" \
      release="0.127.0.0"

RUN yum-config-manager --enable rhel-7-server-ose-3.7-rpms \
                   --enable rhel-7-server-extras-rpms  && \
    packages="elasticsearch-${ES_VER} \
              elasticsearch-cloud-kubernetes \
              java-${JAVA_VER}-openjdk-headless \
              openshift-elasticsearch-plugin \
              PyYAML  \
              zip" && \
    yum install -y --setopt=tsflags=nodocs ${packages} && \
    rpm -V $packages && \
    yum clean all


ADD sgconfig/ ${HOME}/sgconfig/
ADD index_templates/ ${ES_HOME}/index_templates/
ADD index_patterns/ ${ES_HOME}/index_patterns/
ADD kibana_ui_objects/ ${ES_HOME}/kibana_ui_objects/
ADD probe/ ${ES_HOME}/probe/
ADD lib/elasticsearch-prometheus-exporter/elasticsearch-prometheus-exporter-${PROMETHEUS_EXPORTER_VER}.zip /tmp/
ADD run.sh prep-install.${RELEASE_STREAM} install.sh ${HOME}/
COPY utils/** /usr/local/bin/
RUN ln -s /usr/local/bin/logging ${HOME}/logging

RUN ${HOME}/install.sh
RUN rm /tmp/elasticsearch-prometheus-exporter-${PROMETHEUS_EXPORTER_VER}.zip

WORKDIR ${HOME}
USER 1000
CMD ["sh", "/opt/app-root/src/run.sh"]
