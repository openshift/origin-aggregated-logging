#oit## This file is managed by the OpenShift Image Tool: https://github.com/openshift/enterprise-images
#oit## by the OpenShift Continuous Delivery team (#aos-cd-team on IRC).
#oit## 
#oit## Any yum repos listed in this file will effectively be ignored during CD builds.
#oit## Yum repos must be enabled in the oit configuration files.
#oit## The content of this file is managed from an external source.
#oit## Changes made directly in distgit will be lost during the next
#oit## reconciliation process.
#oit## 
FROM rhscl/nodejs-6-rhel7

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 5601

ENV ELASTICSEARCH_URL=https://logging-es:9200 \
    HOME=/opt/app-root/src  \
    KIBANA_BIN=/usr/share/kibana/bin/kibana \
    KIBANA_CONF_DIR=/etc/kibana \
    KIBANA_HOME=/usr/share/kibana \
    KIBANA_VER=5.6.9 \
    NODE_BIN=nodescl-node \
    NODE_ENV=production \
    RELEASE_STREAM=prod

ARG LOCAL_REPO

USER 0

RUN if [ -n "${LOCAL_REPO}" ] ; then \
     curl -s -o /etc/yum.repos.d/local.repo ${LOCAL_REPO} ; \
    fi

ADD *.rpm /tmp/lib/
WORKDIR /tmp/lib
RUN INSTALLED_PKGS="kibana-${KIBANA_VER}-x86_64.rpm" && \
    yum install -y --setopt=tsflags=nodocs  ${INSTALLED_PKGS} && \
    yum clean all

ADD nodescl-node /usr/bin
ADD probe/ /usr/share/kibana/probe/
ADD kibana.yml ${KIBANA_CONF_DIR}/
ADD lib/* ${HOME}/
ADD run.sh utils install.sh prep-install.${RELEASE_STREAM} ${HOME}/
ADD logo-OCP-console-hdr-thin.svg ${KIBANA_HOME}/installedPlugins/origin-kibana/public/images/logo-origin-thin.svg
RUN sh ${HOME}/install.sh
RUN rm -r /tmp/lib

WORKDIR ${HOME}
CMD ["./run.sh"]

LABEL \
        io.k8s.description="Kibana container for querying Elasticsearch for aggregated logs" \
        com.redhat.component="logging-kibana5-container" \
        vendor="Red Hat" \
        name="openshift3/ose-logging-kibana5" \
        License="GPLv2+" \
        io.k8s.display-name="Kibana" \
        version="v3.10.0" \
        architecture="x86_64" \
        release="667" \
        io.openshift.expose-services="5601:http" \
        io.openshift.tags="logging,elk,kibana"

