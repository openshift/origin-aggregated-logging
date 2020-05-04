ARG DATA_VERSION_VALUE=1.6.0
ARG FLUENTD_VERSION_VALUE=1.9.2
ARG HOME_VALUE=/opt/app-root/src
ARG PATH_VALUE=/opt/app-root/src/bin:/opt/app-root/bin
ARG LOGGING_FILE_PATH_VALUE=/var/log/fluentd/fluentd.log
ARG LOGGING_FILE_AGE_VALUE=10
ARG LOGGING_FILE_SIZE_VALUE=1024000
ARG CONTAINER_VALUE=oci

FROM rhscl/ruby-25-rhel7:latest as builder

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

ARG DATA_VERSION_VALUE
ARG FLUENTD_VERSION_VALUE
ARG HOME_VALUE
ARG PATH_VALUE
ARG LOGGING_FILE_PATH_VALUE
ARG LOGGING_FILE_AGE_VALUE
ARG LOGGING_FILE_SIZE_VALUE
ARG CONTAINER_VALUE

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
RUN yum-config-manager --enable rhel-7-server-ose-4.2-rpms && \
  INSTALL_PKGS="make gcc-c++ libffi-devel \
      autoconf automake libtool m4 \
      redhat-rpm-config" && \
  yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
  rpm -V $INSTALL_PKGS && \
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
ADD install-gems.sh *.patch.sh *.patch ${HOME}/vendored_gem_src/

RUN cd ${HOME}/vendored_gem_src/ && ./install-gems.sh && cd / && rm -rf ${HOME}/vendored_gem_src/

FROM rhel7:7-released

ARG DATA_VERSION_VALUE
ARG FLUENTD_VERSION_VALUE
ARG HOME_VALUE
ARG PATH_VALUE
ARG LOGGING_FILE_PATH_VALUE
ARG LOGGING_FILE_AGE_VALUE
ARG LOGGING_FILE_SIZE_VALUE
ARG CONTAINER_VALUE

ENV DATA_VERSION=$DATA_VERSION_VALUE \
    FLUENTD_VERSION=$FLUENTD_VERSION_VALUE \
    HOME=$HOME_VALUE \
    PATH=$PATH_VALUE:$PATH \
    LOGGING_FILE_PATH=$LOGGING_FILE_PATH_VALUE \
    LOGGING_FILE_AGE=$LOGGING_FILE_AGE_VALUE \
    LOGGING_FILE_SIZE=$LOGGING_FILE_SIZE_VALUE \
    container=$CONTAINER_VALUE

#ADD test.repo /etc/yum.repos.d
USER 0
RUN yum-config-manager --enable rhel-7-server-ose-4.2-rpms \
    --enable rhscl-3.2-rh-ruby25-rhel-7> /dev/null && \
  INSTALL_PKGS="hostname \
                bc \
                iproute" && \
  SCL_PKGS="rh-ruby25 rh-ruby25-runtime rh-ruby25-ruby rh-ruby25-rubygem-openssl \
            rh-ruby25-rubygem-json rh-ruby25-ruby-libs rh-ruby25-rubygems \
            rh-ruby25-ruby-irb" && \
  yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS $SCL_PKGS && \
  rpm -V $INSTALL_PKGS $SCL_PKGS && \
  yum clean all

COPY --from=builder /opt/rh/rh-ruby25/root/usr/local/share/gems/gems/** /opt/rh/rh-ruby25/root/usr/local/share/gems/gems/
COPY --from=builder /opt/rh/rh-ruby25/root/usr/local/share/gems/specifications/** /opt/rh/rh-ruby25/root/usr/local/share/gems/specifications/
COPY --from=builder /opt/rh/rh-ruby25/root/usr/local/share/gems/extensions/** /opt/rh/rh-ruby25/root/usr/local/share/gems/extensions/
COPY --from=builder /opt/rh/rh-ruby25/root/usr/local/lib64/gems/ruby/** /opt/rh/rh-ruby25/root/usr/local/lib64/gems/ruby/
COPY --from=builder /opt/rh/rh-ruby25/root/usr/local/lib/** /opt/rh/rh-ruby25/root/usr/local/lib/
COPY --from=builder /opt/rh/rh-ruby25/root/usr/local/bin/** /opt/rh/rh-ruby25/root/usr/local/bin/
COPY --from=builder /usr/local/lib/** /usr/local/lib/
COPY --from=builder /usr/local/bin/** /usr/local/bin/
COPY --from=builder /contents /contents

RUN mkdir -p /etc/fluent/plugin
ADD configs.d/ /etc/fluent/configs.d/
ADD out_syslog_buffered.rb out_syslog.rb out_rawtcp.rb /etc/fluent/plugin/
ADD run.sh generate_syslog_config.rb ${HOME}/
ADD lib/generate_throttle_configs/lib/*.rb ${HOME}/
ADD lib/filter_parse_json_field/lib/*.rb /etc/fluent/plugin/
ADD lib/filter_elasticsearch_genid_ext/lib/filter_elasticsearch_genid_ext.rb /etc/fluent/plugin/
ADD lib/parser_viaq_host_audit/lib/*.rb /etc/fluent/plugin/
ADD lib/fluent-plugin-viaq_data_model/lib/fluent/plugin/*.rb /etc/fluent/plugin/
COPY utils/** /usr/local/bin/

RUN mkdir -p /etc/fluent/configs.d/{dynamic,user} && \
    chmod 777 /etc/fluent/configs.d/dynamic && \
    ln -s /etc/fluent/configs.d/user/fluent.conf /etc/fluent/fluent.conf

WORKDIR ${HOME}
CMD ["scl", "enable", "rh-ruby25", "--", "sh", "run.sh"]

LABEL io.k8s.display-name=Fluentd

LABEL \
        io.k8s.description="Fluentd container for collecting of container logs" \
        com.redhat.component="logging-fluentd-container" \
        vendor="Red Hat" \
        name="openshift3/logging-fluentd" \
        License="GPLv2+" \
        io.k8s.display-name="Fluentd" \
        version="v4.0.0" \
        architecture="x86_64" \
        release="0.0.0.0" \
        io.openshift.tags="logging,elk,fluentd"
