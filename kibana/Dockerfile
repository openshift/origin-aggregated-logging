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
ADD sources /tmp/lib/
WORKDIR /tmp/lib
RUN while read -r hash file ; do \
      curl -s -o $file http://pkgs.devel.redhat.com/repo/containers/logging-kibana5-container/$file/$hash/$file ; \
    done <sources

RUN if [ -n "${LOCAL_REPO}" ] ; then \
     curl -s -o /etc/yum.repos.d/local.repo ${LOCAL_REPO} ; \
    fi

RUN yum repolist > /dev/null && \
    yum-config-manager --enable rhel-7-server-ose-3.9-rpms && \
    yum-config-manager --disable epel >/dev/null || : && \
    INSTALLED_PKGS="kibana-${KIBANA_VER}-x86_64.rpm" && \
    yum install -y --setopt=tsflags=nodocs  ${INSTALLED_PKGS} && \
    yum clean all

ADD nodescl-node /usr/bin
ADD probe/ /usr/share/kibana/probe/
ADD kibana.yml ${KIBANA_CONF_DIR}/
ADD lib ${HOME}
ADD run.sh utils install.sh prep-install.${RELEASE_STREAM} ${HOME}/
ADD logo-OCP-console-hdr-thin.svg ${KIBANA_HOME}/installedPlugins/origin-kibana/public/images/logo-origin-thin.svg
RUN sh ${HOME}/install.sh
RUN rm -r /tmp/lib

WORKDIR ${HOME}
CMD ["./run.sh"]

LABEL \
        io.k8s.description="Kibana container for querying Elasticsearch for aggregated logs" \
        com.redhat.component="logging-kibana-docker" \
        vendor="Red Hat" \
        name="openshift3/logging-kibana" \
        License="GPLv2+" \
        io.k8s.display-name="Kibana" \
        version="v3.9.16" \
        architecture="x86_64" \
        release="1" \
        io.openshift.expose-services="5601:http" \
        io.openshift.tags="logging,elk,kibana"

