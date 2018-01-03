FROM rhscl/nodejs-6-rhel7

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 5601

ENV ELASTICSEARCH_URL=https://localhost:9200 \
    HOME=/opt/app-root/src  \
    KIBANA_HOME=/usr/share/kibana \
    KIBANA_CONF_DIR=/etc/kibana \
    CONFIG_PATH=/etc/kibana \
    NODE_ENV=production \
    KIBANA_VER=5.5.2 \
    NODE_BIN=nodescl-node \
    RELEASE_STREAM=prod

LABEL io.k8s.description="Kibana container for querying Elasticsearch for aggregated logs" \
      io.k8s.display-name="Kibana" \
      io.openshift.expose-services="5601:http" \
      io.openshift.tags="logging,elk,kibana" \
      com.redhat.component=logging-kibana-docker \
      architecture=x86_64 \
      name="openshift3/logging-kibana" \
      version="3.6.0" \
      release="1"

USER 0

RUN yum repolist > /dev/null && \
    yum-config-manager --enable rhel-7-server-ose-3.7-rpms && \
    yum-config-manager --disable epel >/dev/null || : && \
    INSTALLED_PKGS="kibana-${KIBANA_VER}" && \
    yum install -y --setopt=tsflags=nodocs  ${INSTALLED_PKGS} && \
    rpm -V ${INSTALLED_PKGS} && \
    yum clean all

ADD nodescl-node /usr/bin
ADD probe/ /usr/share/kibana/probe/
ADD lib ${HOME}
ADD kibana.yml ${KIBANA_CONF_DIR}/
ADD run.sh utils install.sh prep-install.${RELEASE_STREAM} ${HOME}/
RUN sh ${HOME}/install.sh

WORKDIR ${HOME}
CMD ["./run.sh"]
