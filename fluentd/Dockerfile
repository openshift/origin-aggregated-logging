FROM registry.svc.ci.openshift.org/ocp/builder:ubi8.ruby.25 AS builder

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

RUN BUILD_PKGS="make gcc-c++ libffi-devel \
              autoconf automake libtool m4 \
              redhat-rpm-config" && \
  RUNTIME_PKGS="hostname \
                bc \
                iproute" && \
  yum install -y --setopt=tsflags=nodocs $BUILD_PKGS $RUNTIME_PKGS && \
  rpm -V $BUILD_PKGS && \
  rpm -V $RUNTIME_PKGS && \
  yum clean all

# uncomment if you want to try out test rpm builds
#ADD *.rpm /tmp/
#RUN yum -y install /tmp/*.rpm

ADD jemalloc/ ${HOME}/jemalloc/
RUN cd ${HOME}/jemalloc && EXTRA_CFLAGS="$( rpm --eval '%{optflags}' )" ./autogen.sh && \
    make install_lib_shared install_bin && cp COPYING ${HOME}/COPYING.jemalloc && \
    cd .. && rm -rf jemalloc

ADD source.jemalloc /source.jemalloc
RUN bash -c '. /source.jemalloc; echo jemalloc $JEMALLOC_VER >> /contents'

ADD vendored_gem_src/ ${HOME}/vendored_gem_src/
ADD lib/fluent-plugin-remote_syslog/ ${HOME}/vendored_gem_src/fluent-plugin-remote_syslog/
ADD lib/remote_syslog_sender/        ${HOME}/vendored_gem_src/remote_syslog_sender/
ADD lib/syslog_protocol/             ${HOME}/vendored_gem_src/syslog_protocol/
ADD install-gems.sh *.patch.sh *.patch ${HOME}/vendored_gem_src/

RUN cd ${HOME}/vendored_gem_src/ && ./install-gems.sh && cd / && rm -rf ${HOME}/vendored_gem_src/

RUN BUILD_PKGS="make gcc-c++ libffi-devel \
                autoconf automake libtool m4 \
                redhat-rpm-config" && \
    yum remove -y $BUILD_PKGS

RUN mkdir -p /etc/fluent/plugin
ADD configs.d/ /etc/fluent/configs.d/
ADD out_syslog_buffered.rb out_syslog.rb out_rawtcp.rb /etc/fluent/plugin/
ADD run.sh generate_syslog_config.rb wait_for_es_version.rb wait_for_es_version.sh ${HOME}/
ADD lib/generate_throttle_configs/lib/*.rb ${HOME}/
ADD lib/filter_parse_json_field/lib/*.rb /etc/fluent/plugin/
ADD lib/filter_elasticsearch_genid_ext/lib/filter_elasticsearch_genid_ext.rb /etc/fluent/plugin/
ADD lib/parser_viaq_host_audit/lib/*.rb /etc/fluent/plugin/
ADD lib/fluent-plugin-viaq_data_model/lib/fluent/plugin/*.rb /etc/fluent/plugin/
COPY utils/ /usr/local/bin/

RUN mkdir -p /etc/fluent/configs.d/{dynamic,user} && \
    chmod 777 /etc/fluent/configs.d/dynamic && \
    ln -s /etc/fluent/configs.d/user/fluent.conf /etc/fluent/fluent.conf

WORKDIR ${HOME}
CMD ["sh", "run.sh"]
