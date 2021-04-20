FROM registry.ci.openshift.org/ocp/builder:ubi8.ruby.25

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

ENV DATA_VERSION=1.6.0 \
    FLUENTD_VERSION=1.7.4 \
    HOME=/opt/app-root/src \
    PATH=/opt/app-root/src/bin:/opt/app-root/bin:$PATH \
    LOGGING_FILE_PATH=/var/lib/fluentd/fluentd.log \
    LOGGING_FILE_AGE=10 \
    LOGGING_FILE_SIZE=1024000 \
    container=oci

ARG BUILD_PKGS="make gcc-c++ libffi-devel autoconf automake libtool m4 redhat-rpm-config"
ARG RUNTIME_PKGS="hostname bc iproute"

USER 0

RUN yum install -y $BUILD_PKGS $RUNTIME_PKGS && \
    rpm -V $BUILD_PKGS $RUNTIME_PKGS && \
    yum clean all

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

RUN yum remove -y $BUILD_PKGS

RUN mkdir -p /etc/fluent/plugin
ADD out_syslog_buffered.rb out_syslog.rb out_rawtcp.rb /etc/fluent/plugin/
ADD run.sh wait_for_es_version.rb wait_for_es_version.sh ${HOME}/
ADD lib/filter_parse_json_field/lib/*.rb /etc/fluent/plugin/
ADD lib/filter_elasticsearch_genid_ext/lib/filter_elasticsearch_genid_ext.rb /etc/fluent/plugin/
ADD lib/parser_viaq_host_audit/lib/*.rb /etc/fluent/plugin/
ADD lib/fluent-plugin-viaq_data_model/lib/fluent/plugin/*.rb /etc/fluent/plugin/
COPY utils/ /usr/local/bin/

RUN mkdir -p /etc/fluent/configs.d/user && \
    chmod 777 /etc/fluent/configs.d/user && \
	ln -s /etc/fluent/configs.d/user/fluent.conf /etc/fluent/fluent.conf

WORKDIR ${HOME}
CMD ["sh", "run.sh"]
