FROM rhscl/nodejs-6-rhel7

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 5601

ENV ELASTICSEARCH_URL=https://logging-es:9200 \
    HOME=/opt/app-root/src  \
    KIBANA_BIN=/usr/share/kibana/bin/kibana \
    KIBANA_CONF_DIR=/etc/kibana \
    KIBANA_HOME=/usr/share/kibana \
    KIBANA_VER=5.6.13 \
    NODE_BIN=nodescl-node \
    NODE_ENV=production \
    RELEASE_STREAM=prod \
    container=oci

ARG LOCAL_REPO

USER 0

RUN if [ -n "${LOCAL_REPO}" ] ; then \
     curl -s -o /etc/yum.repos.d/local.repo ${LOCAL_REPO} ; \
    fi

RUN INSTALLED_PKGS="kibana-${KIBANA_VER}*" && \
    yum install -y --setopt=tsflags=nodocs  ${INSTALLED_PKGS} zip && \
    yum clean all

ADD nodescl-node /usr/bin
ADD probe/ /usr/share/kibana/probe/
ADD kibana.yml ${KIBANA_CONF_DIR}/
ADD lib/* ${HOME}/
ADD patches/ ${HOME}/patches/
ADD run.sh utils install.sh prep-install.${RELEASE_STREAM} ${HOME}/
ADD logo-OCP-console-hdr-stacked.svg ${HOME}/kibana/origin-kibana/public/images/logo-okd.svg
RUN (type -p node || ln -s $(which $NODE_BIN) "/usr/bin/node") && \
    sh ${HOME}/install.sh

WORKDIR ${HOME}
CMD ["./run.sh"]

LABEL \
        io.k8s.description="Kibana container for querying Elasticsearch for aggregated logs" \
        com.redhat.component="logging-kibana5-container" \
        vendor="Red Hat" \
        name="openshift3/ose-logging-kibana5" \
        License="GPLv2+" \
        io.k8s.display-name="Kibana" \
        version="v3.11.0" \
        architecture="x86_64" \
        release="0.69.0.0" \
        io.openshift.expose-services="5601:http" \
        io.openshift.tags="logging,elk,kibana"

