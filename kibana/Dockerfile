FROM openshift/base-centos7

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 5601

ENV KIBANA_VER=4.6.4 \
    ES_HOST=localhost \
    ES_PORT=9200 \
    HOME=/opt/app-root/src \
    KIBANA_HOME=/opt/kibana \
    AOP_KIBANA_PLUGIN_VER=v4.5.1-2 \
    AOP_KIBANA_PLUGIN_REPO=https://github.com/openshift/origin-kibana

LABEL io.k8s.description="Kibana container for querying Elasticsearch for aggregated logs" \
  io.k8s.display-name="Kibana" \
  io.openshift.expose-services="5601:http" \
  io.openshift.tags="logging,elk,kibana"

ADD kibana.repo /etc/yum.repos.d/kibana.repo
# install the RPMs in a separate step so it can be cached
RUN rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch && \
    yum install -y --setopt=tsflags=nodocs \
                kibana-${KIBANA_VER} && \
    yum clean all

COPY kibana.yml ${KIBANA_HOME}/config/kibana.yml
COPY run.sh install.sh ${HOME}/
RUN sh install.sh

USER default

CMD ["sh", "run.sh"]
