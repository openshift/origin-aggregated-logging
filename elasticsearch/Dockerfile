FROM centos:centos7

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 9200
EXPOSE 9300
USER 0

ENV HOME=/opt/app-root/src \
  JAVA_VER=1.8.0 \
  ES_VER=2.4.1 \
  SG_VER=2.4.1.8 \
  SG_SSL_VER=2.4.1.16 \
  ES_CLOUD_K8S_VER=2.4.1 \
  OSE_ES_VER=2.4.1.12 \
  ES_CONF=/usr/share/elasticsearch/config \
  INSTANCE_RAM=512G \
  NODE_QUORUM=1 \
  RECOVER_AFTER_NODES=1 \
  RECOVER_EXPECTED_NODES=1 \
  RECOVER_AFTER_TIME=5m \
  PLUGIN_LOGLEVEL=INFO \
  ES_JAVA_OPTS="-Dmapper.allow_dots_in_name=true"

LABEL io.k8s.description="Elasticsearch container to serve as EFK aggregated logging backend" \
  io.k8s.display-name="Elasticsearch ${ES_VER}" \
  io.openshift.expose-services="9200:https, 9300:https" \
  io.openshift.tags="logging,elasticsearch"

ADD elasticsearch.repo /etc/yum.repos.d/elasticsearch.repo
# install the RPMs in a separate step so it can be cached
RUN rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch && \
    yum install -y centos-release-scl && \
    yum-config-manager --enable rhel-server-rhscl-7-rpms && \
    yum install -y --setopt=tsflags=nodocs \
                java-1.8.0-openjdk-headless \
                rh-maven33 \
                elasticsearch-${ES_VER} \
                PyYAML && \
    yum clean all

ADD sgconfig/ ${HOME}/sgconfig/
ADD index_templates/ /usr/share/elasticsearch/index_templates/
ADD index_patterns/ /usr/share/elasticsearch/index_patterns/
ADD run.sh install.sh ${HOME}/
COPY utils/** /usr/local/bin/
RUN ln -s /usr/local/bin/logging ${HOME}/logging
ADD lib /tmp/lib/

RUN ${HOME}/install.sh && yum erase -y rh-maven33

WORKDIR ${HOME}
USER 1000
CMD ["sh", "/opt/app-root/src/run.sh"]
