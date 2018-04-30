FROM rhel7:7-released

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 9200
EXPOSE 9300
USER 0

ENV ES_CLOUD_K8S_VER=5.6.9 \
    ES_CONF=/etc/elasticsearch/ \
    ES_JAVA_OPTS="-Dmapper.allow_dots_in_name=true" \
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

ARG ES_CLOUD_K8S_VER=5.6.9
ARG OSE_ES_VER=5.6.9.1
ARG ES_CLOUD_K8S_URL
ARG OSE_ES_URL
ARG PROMETHEUS_EXPORTER_URL
ARG LOCAL_REPO

ADD sources /tmp/lib/
WORKDIR /tmp/lib
RUN while read -r hash file ; do \
      curl -s -o $file http://pkgs.devel.redhat.com/repo/containers/logging-elasticsearch5-container/$file/$hash/$file ; \
    done <sources

RUN if [ -n "${LOCAL_REPO}" ] ; then \
     curl -s -o /etc/yum.repos.d/local.repo ${LOCAL_REPO} ; \
    fi

RUN yum-config-manager --enable rhel-7-server-ose-3.8-rpms \
                   --enable rhel-7-server-extras-rpms  && \
    packages="elasticsearch-${ES_VER}.rpm \
              java-${JAVA_VER}-openjdk-headless \
              PyYAML  \
              zip" && \
    yum install -y --setopt=tsflags=nodocs ${packages} && \
    yum clean all

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
        com.redhat.component="logging-elasticsearch-docker" \
        vendor="Red Hat" \
        name="openshift3/logging-elasticsearch" \
        License="GPLv2+" \
        io.k8s.display-name="Elasticsearch 5" \
        version="v3.9.16" \
        architecture="x86_64" \
        release="1" \
        io.openshift.expose-services="9200:https, 9300:https" \
        io.openshift.tags="logging,elk,elasticsearch"

