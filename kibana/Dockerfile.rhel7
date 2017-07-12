FROM rhel7.3:7.3-released

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 5601

ENV AOP_KIBANA_PLUGIN_VER=4.5.1 \
    ES_HOST=localhost \
    ES_PORT=9200 \
    HOME=/opt/app-root/src  \
    KIBANA_HOME=/usr/share/kibana \
    KIBANA_CONF_DIR=/etc/kibana \
    CONFIG_PATH=/etc/kibana \
    NODE_ENV=production \
    KIBANA_VER=4.6.4 \
    NODE_BIN=/usr/bin/node \
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

RUN yum-config-manager --enable rhel-7-server-ose-3.6-rpms && \
    INSTALLED_PKGS="kibana-${KIBANA_VER} \
                    origin-kibana-${AOP_KIBANA_PLUGIN_VER}" && \
    yum install -y --setopt=tsflags=nodocs  ${INSTALLED_PKGS} && \
    rpm -V ${INSTALLED_PKGS} && \
    yum clean all

ADD probe/ /usr/share/kibana/probe/
ADD kibana.yml ${KIBANA_CONF_DIR}/
ADD run.sh install.sh prep-install.${RELEASE_STREAM} ${HOME}/
RUN sh ${HOME}/install.sh

WORKDIR ${HOME}
CMD ["./run.sh"]
