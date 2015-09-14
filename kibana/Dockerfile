FROM openshift/base-centos7

MAINTAINER Eric Wolinetz <ewolinet@redhat.com>

ENV KIBANA_VER 4.1.1

LABEL io.k8s.description="Kibana container for querying Elasticsearch for aggregated logs" \
  io.k8s.display-name="Kibana" \
  io.openshift.expose-services="5601:http" \
  io.openshift.tags="logging,elk,kibana"

RUN wget -q https://download.elastic.co/kibana/kibana/kibana-4.1.1-linux-x64.tar.gz && \
  tar -xzf kibana-4.1.1-linux-x64.tar.gz && \
  mv kibana-4.1.1-linux-x64/* /opt/app-root/src/ && \
  rm -rf kibana-4.1.1-linux-x64* && \
  chmod -R og+w /opt/app-root/src

COPY kibana.yml /opt/app-root/src/config/kibana.yml
COPY run.sh /opt/app-root/src/run.sh

USER default

CMD ["sh", "run.sh"]
