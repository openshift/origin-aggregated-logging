FROM openshift/base-centos7

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 5601

ENV KIBANA_VER=4.5.4 \
    ES_HOST=localhost \
    ES_PORT=9200 \
    HOME=/opt/app-root/src \
    KIBANA_HOME=${HOME} \
    AOP_KIBANA_PLUGIN_VER=v4.5.1-0 \
    AOP_KIBANA_PLUGIN_REPO=https://github.com/openshift/origin-kibana

LABEL io.k8s.description="Kibana container for querying Elasticsearch for aggregated logs" \
  io.k8s.display-name="Kibana" \
  io.openshift.expose-services="5601:http" \
  io.openshift.tags="logging,elk,kibana"

COPY kibana.yml ${KIBANA_HOME}/config/kibana.yml
COPY run.sh install.sh ${HOME}/
RUN sh install.sh

USER default

CMD ["sh", "run.sh"]
