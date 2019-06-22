FROM centos/ruby-25-centos7:latest

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

ENV DATA_VERSION=1.6.0 \
    FLUENTD_VERSION=1.5.1 \
    GEM_HOME=/opt/app-root/src \
    HOME=/opt/app-root/src \
    PATH=/opt/app-root/src/bin:/opt/app-root/bin:$PATH \
    LOGGING_FILE_PATH=/var/log/fluentd/fluentd.log \
    LOGGING_FILE_AGE=10 \
    LOGGING_FILE_SIZE=1024000

# iproute needed for ip command to get ip addresses
# autoconf redhat-rpm-config for building jemalloc
USER 0
RUN rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    yum install -y --setopt=tsflags=nodocs \
      make \
      bc \
      git \
      libffi-devel \
      iproute \
      autoconf automake libtool m4 \
      redhat-rpm-config && \
    yum clean all

ADD jemalloc/ ${HOME}/jemalloc/
RUN cd ${HOME}/jemalloc && EXTRA_CFLAGS="$( rpm --eval '%{optflags}' )" ./autogen.sh && \
    make install_lib_shared install_bin && cp COPYING ${HOME}/COPYING.jemalloc && \
    cd .. && rm -rf jemalloc

ADD source.jemalloc /source.jemalloc
RUN bash -c '. /source.jemalloc; echo jemalloc $JEMALLOC_VER >> /contents'

ADD vendored_gem_src/ ${HOME}/vendored_gem_src/
ADD install-gems.sh *.patch.sh *.patch ${HOME}/vendored_gem_src/

RUN cd ${HOME}/vendored_gem_src/ && ./install-gems.sh && cd / && rm -rf ${HOME}/vendored_gem_src/

RUN mkdir -p /etc/fluent/plugin
ADD configs.d/ /etc/fluent/configs.d/
ADD out_syslog_buffered.rb out_syslog.rb out_rawtcp.rb /etc/fluent/plugin/
ADD parser_viaq_docker_audit.rb viaq_docker_audit.rb /etc/fluent/plugin/
ADD run.sh generate_syslog_config.rb ${HOME}/
ADD lib/generate_throttle_configs/lib/*.rb ${HOME}/
ADD lib/filter_parse_json_field/lib/*.rb /etc/fluent/plugin/
ADD lib/filter_elasticsearch_genid_ext/lib/filter_elasticsearch_genid_ext.rb /etc/fluent/plugin/
COPY utils/** /usr/local/bin/

RUN mkdir -p /etc/fluent/configs.d/{dynamic,user} && \
    chmod 777 /etc/fluent/configs.d/dynamic && \
    ln -s /etc/fluent/configs.d/user/fluent.conf /etc/fluent/fluent.conf

WORKDIR ${HOME}
USER 0
CMD ["sh", "run.sh"]
