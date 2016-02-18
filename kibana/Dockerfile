FROM openshift/base-centos7

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 5601

ENV KIBANA_VER=4.1.2 \
    ES_HOST=localhost \
    ES_PORT=9200 \
    AOP_KIBANA_PLUGIN_VER=v0.5.0 \
    AOP_KIBANA_PLUGIN_REPO=https://github.com/openshift/origin-kibana

LABEL io.k8s.description="Kibana container for querying Elasticsearch for aggregated logs" \
  io.k8s.display-name="Kibana" \
  io.openshift.expose-services="5601:http" \
  io.openshift.tags="logging,elk,kibana"

RUN   wget -q https://download.elastic.co/kibana/kibana/kibana-${KIBANA_VER}-linux-x64.tar.gz && \
      tar -xzf kibana-${KIBANA_VER}-linux-x64.tar.gz && \
      mv kibana-${KIBANA_VER}-linux-x64/* /opt/app-root/src/ && \
      rm -rf kibana-${KIBANA_VER}-linux-x64* && \
      mkdir -p -m 755 /opt/origin-kibana/lib && \
      cd /opt/origin-kibana/lib && \
      wget -q ${AOP_KIBANA_PLUGIN_REPO}/releases/download/${AOP_KIBANA_PLUGIN_VER}/origin-kibana-${AOP_KIBANA_PLUGIN_VER}.tgz && \
      tar -xvzf origin-kibana-${AOP_KIBANA_PLUGIN_VER}.tgz && \
      rm origin-kibana-*.tgz && \
      ln -s /opt/origin-kibana/lib /opt/app-root/src/src/public/plugins/origin-kibana && \
      chmod -R og+w /opt/app-root/src

COPY kibana.yml /opt/app-root/src/config/kibana.yml
COPY run.sh /opt/app-root/src/run.sh

USER default

CMD ["sh", "run.sh"]
