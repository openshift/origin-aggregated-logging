#oit## This file is managed by the OpenShift Image Tool: https://github.com/openshift/enterprise-images
#oit## by the OpenShift Continuous Delivery team (#aos-cd-team on IRC).
#oit## 
#oit## Any yum repos listed in this file will effectively be ignored during CD builds.
#oit## Yum repos must be enabled in the oit configuration files.
#oit## The content of this file is managed from an external source.
#oit## Changes made directly in distgit will be lost during the next
#oit## reconciliation process.
#oit## 
FROM rhel7:7-released

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 9200
EXPOSE 9300
USER 0

ENV ES_CLOUD_K8S_VER=5.6.9.2 \
    ES_CONF=/etc/elasticsearch/ \
    ES_HOME=/usr/share/elasticsearch \
    ES_VER=5.6.9 \
    HOME=/opt/app-root/src \
    INSTANCE_RAM=512G \
    JAVA_VER=1.8.0 \
    NODE_QUORUM=1 \
    OSE_ES_VER=5.6.9.0 \
    PROMETHEUS_EXPORTER_VER=5.6.9.0 \
    PLUGIN_LOGLEVEL=INFO \
    RECOVER_AFTER_NODES=1 \
    RECOVER_EXPECTED_NODES=1 \
    RECOVER_AFTER_TIME=5m \
    RELEASE_STREAM=prod

ARG ES_CLOUD_K8S_VER=5.6.9.2
ARG OSE_ES_VER=5.6.9.0
ARG ES_CLOUD_K8S_URL
ARG OSE_ES_URL
ARG PROMETHEUS_EXPORTER_URL
ARG LOCAL_REPO

RUN if [ -n "${LOCAL_REPO}" ] ; then \
     curl -s -o /etc/yum.repos.d/local.repo ${LOCAL_REPO} ; \
    fi

ADD *.rpm /tmp/ocp/
ADD *.zip /tmp/lib/

RUN yum install -y --setopt=tsflags=nodocs /tmp/ocp/*.rpm && \
    packages="java-${JAVA_VER}-openjdk-headless \
              hostname \
              PyYAML  \
              zip" && \
    yum install -y --setopt=tsflags=nodocs ${packages} && \
    yum clean all && \
    rm -rf /tmp/ocp

ADD sgconfig/ ${HOME}/sgconfig/
ADD index_templates/ ${ES_HOME}/index_templates/
ADD index_patterns/ ${ES_HOME}/index_patterns/
ADD kibana_ui_objects/ ${ES_HOME}/kibana_ui_objects/
ADD probe/ ${ES_HOME}/probe/
ADD run.sh prep-install.${RELEASE_STREAM} install.sh ${HOME}/
COPY utils/** /usr/local/bin/
RUN ln -s /usr/local/bin/logging ${HOME}/logging

RUN ${HOME}/install.sh
RUN rm -r /tmp/lib

WORKDIR ${HOME}
USER 1000
CMD ["sh", "/opt/app-root/src/run.sh"]

LABEL \
        io.k8s.description="Elasticsearch container for EFK aggregated logging storage" \
        com.redhat.component="logging-elasticsearch5-container" \
        vendor="Red Hat" \
        name="openshift3/ose-logging-elasticsearch5" \
        License="GPLv2+" \
        io.k8s.display-name="Elasticsearch 5" \
        version="v3.10.0" \
        architecture="x86_64" \
        release="667" \
        io.openshift.expose-services="9200:https, 9300:https" \
        io.openshift.tags="logging,elk,elasticsearch"

