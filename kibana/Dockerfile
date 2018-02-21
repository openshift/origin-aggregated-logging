#oit## This file is managed by the OpenShift Image Tool: https://github.com/openshift/enterprise-images
#oit## by the OpenShift Continuous Delivery team (#aos-cd-team on IRC).
#oit## 
#oit## Any yum repos listed in this file will effectively be ignored during CD builds.
#oit## Yum repos must be enabled in the oit configuration files.
#oit## Some aspects of this file may be managed programmatically. For example, the image name, labels (version,
#oit## release, and other), and the base FROM. Changes made directly in distgit may be lost during the next
#oit## reconciliation.
#oit## 
FROM rhscl/nodejs-6-rhel7

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 5601

ENV ES_HOST=localhost \
    ES_PORT=9200 \
    HOME=/opt/app-root/src  \
    KIBANA_HOME=/usr/share/kibana \
    KIBANA_CONF_DIR=/etc/kibana \
    CONFIG_PATH=/etc/kibana \
    NODE_ENV=production \
    KIBANA_VER=4.6.4 \
    NODE_BIN=nodescl-node \
    RELEASE_STREAM=prod

USER 0

RUN yum repolist > /dev/null && \
    yum-config-manager --enable rhel-7-server-ose-3.9-rpms && \
    yum-config-manager --disable epel >/dev/null || : && \
    INSTALLED_PKGS="kibana-${KIBANA_VER}" && \
    yum install -y --setopt=tsflags=nodocs  ${INSTALLED_PKGS} && \
    rpm -V ${INSTALLED_PKGS} && \
    yum clean all

ADD nodescl-node /usr/bin
ADD probe/ /usr/share/kibana/probe/
ADD lib/origin-kibana ${KIBANA_HOME}/installedPlugins/origin-kibana
ADD kibana.yml ${KIBANA_CONF_DIR}/
ADD run.sh utils install.sh prep-install.${RELEASE_STREAM} ${HOME}/
ADD logo-OCP-console-hdr-thin.svg ${KIBANA_HOME}/installedPlugins/origin-kibana/public/images/logo-origin-thin.svg
RUN sh ${HOME}/install.sh

WORKDIR ${HOME}
CMD ["./run.sh"]

LABEL \
        io.k8s.description="Kibana container for querying Elasticsearch for aggregated logs" \
        com.redhat.component="logging-kibana-docker" \
        vendor="Red Hat" \
        name="openshift3/logging-kibana" \
        License="GPLv2+" \
        io.k8s.display-name="Kibana" \
        version="v3.9.0" \
        architecture="x86_64" \
        release="0.46.0.0" \
        io.openshift.expose-services="5601:http" \
        io.openshift.tags="logging,elk,kibana"

