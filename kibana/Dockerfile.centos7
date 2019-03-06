FROM openshift/base-centos7

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 5601

ENV ELASTICSEARCH_URL=https://logging-es:9200 \
    HOME=/opt/app-root/src \
    KIBANA_BIN=/usr/share/kibana/bin/kibana \
    KIBANA_CONF_DIR=/etc/kibana \
    KIBANA_HOME=/usr/share/kibana \
    KIBANA_VER=5.6.13 \
    RELEASE_STREAM=origin

LABEL io.k8s.description="Kibana container for querying Elasticsearch for aggregated logs" \
      io.k8s.display-name="Kibana" \
      io.openshift.expose-services="5601:http" \
      io.openshift.tags="logging,elk,kibana"

ADD kibana.repo /etc/yum.repos.d/kibana.repo
# install the RPMs in a separate step so it can be cached
RUN rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch && \
    INSTALLED_PKGS="kibana-${KIBANA_VER}" && \
    yum install -y --setopt=tsflags=nodocs  ${INSTALLED_PKGS} && \
    yum clean all

ADD probe/ /usr/share/kibana/probe/
ADD kibana.yml ${KIBANA_CONF_DIR}/
ADD lib/* ${HOME}/
ADD patches/ ${HOME}/patches/
ADD run.sh utils install.sh prep-install.${RELEASE_STREAM} ${HOME}/
RUN ${HOME}/install.sh

WORKDIR ${HOME}
CMD ["./run.sh"]
