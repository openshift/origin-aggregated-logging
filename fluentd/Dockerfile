### This is a generated file from Dockerfile.in ###

#@follow_tag(openshift-ose-base:ubi8.ruby.25)
FROM registry.ci.openshift.org/ocp/builder:ubi8.ruby.25

ENV BUILD_VERSION=${CI_CONTAINER_VERSION:-}
ENV OS_GIT_MAJOR=${CI_X_VERSION:-}
ENV OS_GIT_MINOR=${CI_Y_VERSION:-}
ENV OS_GIT_PATCH=${CI_Z_VERSION:-}
ENV SOURCE_GIT_COMMIT=${CI_ORIGIN_AGGREGATED_LOGGING_UPSTREAM_COMMIT:-}
ENV SOURCE_GIT_URL=${CI_ORIGIN_AGGREGATED_LOGGING_UPSTREAM_URL:-}

LABEL \
        License="GPLv2+" \
        io.k8s.description="Fluentd container for collecting of container logs" \
        io.k8s.display-name="Fluentd" \
        io.openshift.tags="logging,elk,fluentd" \
        vendor="Red Hat" \
        name="openshift/ose-logging-fluentd" \
        com.redhat.component="logging-fluentd-container" \
        io.openshift.maintainer.product="OpenShift Container Platform" \
        io.openshift.build.commit.id=${CI_ORIGIN_AGGREGATED_LOGGING_UPSTREAM_COMMIT} \
        io.openshift.build.source-location=${CI_ORIGIN_AGGREGATED_LOGGING_UPSTREAM_URL} \
        io.openshift.build.commit.url=${CI_ORIGIN_AGGREGATED_LOGGING_UPSTREAM_URL}/commit/${CI_ORIGIN_AGGREGATED_LOGGING_UPSTREAM_URL} \
        version=${CI_CONTAINER_VERSION}

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

ARG DATA_VERSION_VALUE=1.6.0
ARG FLUENTD_VERSION_VALUE=1.7.4
ARG HOME_VALUE=/opt/app-root/src
ARG PATH_VALUE=/opt/app-root/src/bin:/opt/app-root/bin
ARG LOGGING_FILE_PATH_VALUE=/var/log/fluentd/fluentd.log
ARG LOGGING_FILE_AGE_VALUE=10
ARG LOGGING_FILE_SIZE_VALUE=1024000
ARG CONTAINER_VALUE=oci

ENV DATA_VERSION=$DATA_VERSION_VALUE \
    FLUENTD_VERSION=$FLUENTD_VERSION_VALUE \
    HOME=$HOME_VALUE \
    PATH=$PATH_VALUE:$PATH \
    LOGGING_FILE_PATH=$LOGGING_FILE_PATH_VALUE \
    LOGGING_FILE_AGE=$LOGGING_FILE_AGE_VALUE \
    LOGGING_FILE_SIZE=$LOGGING_FILE_SIZE_VALUE \
    container=$CONTAINER_VALUE


ARG TEST_REPO
#ADD test.repo /etc/yum.repos.d

USER 0
RUN : 'removed yum-config-manager' \
 &&   BUILD_PKGS="make gcc-c++ libffi-devel autoconf automake libtool m4 redhat-rpm-config" \
 &&   RUNTIME_PKGS="hostname   bc  iproute" \
 &&   yum install -y --setopt=tsflags=nodocs $BUILD_PKGS $RUNTIME_PKGS \
 &&   rpm -V $BUILD_PKGS \
 &&   rpm -V $RUNTIME_PKGS \
 &&   yum clean all

# uncomment if you want to try out test rpm builds
#ADD *.rpm /tmp/
#RUN yum -y install /tmp/*.rpm
ENV upstream_code=${upstream_code:-"."}
COPY  ${upstream_code}/jemalloc/ ${HOME}/jemalloc/
RUN cd ${HOME}/jemalloc && EXTRA_CFLAGS="$( rpm --eval '%{optflags}' )" ./autogen.sh && \
    make install_lib_shared install_bin && cp COPYING ${HOME}/COPYING.jemalloc && \
    cd .. && rm -rf jemalloc

COPY  ${upstream_code}/source.jemalloc /source.jemalloc
RUN bash -c '. /source.jemalloc; echo jemalloc $JEMALLOC_VER >> /contents'

COPY  ${upstream_code}/vendored_gem_src/ ${HOME}/vendored_gem_src/
COPY  ${upstream_code}/lib/fluent-plugin-remote_syslog/ ${HOME}/vendored_gem_src/fluent-plugin-remote_syslog/
COPY  ${upstream_code}/lib/fluent-plugin-collected/ ${HOME}/vendored_gem_src/fluent-plugin-collected/
COPY  ${upstream_code}/lib/remote_syslog_sender/ ${HOME}/vendored_gem_src/remote_syslog_sender/
COPY  ${upstream_code}/lib/syslog_protocol/ ${HOME}/vendored_gem_src/syslog_protocol/
COPY  ${upstream_code}/install-gems.sh ${HOME}/vendored_gem_src/
COPY  ${upstream_code}/*.patch.sh ${HOME}/vendored_gem_src/
COPY  ${upstream_code}/*.patch ${HOME}/vendored_gem_src/

RUN cd ${HOME}/vendored_gem_src/ && ./install-gems.sh && cd / && rm -rf ${HOME}/vendored_gem_src/

RUN BUILD_PKGS="make gcc-c++ libffi-devel \
                autoconf automake libtool m4 \
                redhat-rpm-config" && \
    yum remove -y $BUILD_PKGS

RUN mkdir -p /etc/fluent/plugin

COPY  ${upstream_code}/out_syslog_buffered.rb /etc/fluent/plugin/
COPY  ${upstream_code}/out_syslog.rb /etc/fluent/plugin/
COPY  ${upstream_code}/out_rawtcp.rb /etc/fluent/plugin/

COPY  ${upstream_code}/run.sh ${HOME}/
COPY  ${upstream_code}/generate_syslog_config.rb ${HOME}/
COPY  ${upstream_code}/wait_for_es_version.rb ${HOME}/
COPY  ${upstream_code}/wait_for_es_version.sh ${HOME}/

COPY  ${upstream_code}/lib/filter_parse_json_field/lib/*.rb /etc/fluent/plugin/
COPY  ${upstream_code}/lib/filter_elasticsearch_genid_ext/lib/filter_elasticsearch_genid_ext.rb /etc/fluent/plugin/
COPY  ${upstream_code}/lib/parser_viaq_host_audit/lib/*.rb /etc/fluent/plugin/
COPY  ${upstream_code}/lib/fluent-plugin-viaq_data_model/lib/fluent/plugin/*.rb /etc/fluent/plugin/
COPY  ${upstream_code}/utils/ /usr/local/bin/

RUN mkdir -p /etc/fluent/configs.d/user && \    
    chmod 777 /etc/fluent/configs.d/user && \    
    ln -s /etc/fluent/configs.d/user/fluent.conf /etc/fluent/fluent.conf 

WORKDIR ${HOME}
CMD ["sh", "run.sh"]

