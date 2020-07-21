FROM ubi7/ruby-25:latest as builder


MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

ENV DATA_VERSION=1.6.0 \
    FLUENTD_VERSION=1.7.4 \
    GEM_HOME=/usr/share/gems \
    HOME=/opt/app-root/src \
    PATH=/opt/app-root/src/bin:/opt/app-root/bin:/usr/libexec/fluentd/bin:$PATH \
    RUBY_VERSION=2.0 \
    LOGGING_FILE_PATH=/var/log/fluentd/fluentd.log \
    LOGGING_FILE_AGE=10 \
    LOGGING_FILE_SIZE=1024000 \
    container=oci

USER 0
RUN yum-config-manager --enable rhel-server-rhscl-rpms && \
  BUILD_PKGS="make gcc-c++ libffi-devel \
              autoconf automake libtool m4 \
              redhat-rpm-config" && \
  RUNTIME_PKGS="hostname \
                bc \
                iproute" && \
  yum install -y --setopt=tsflags=nodocs $BUILD_PKGS $RUNTIME_PKGS && \
  rpm -V $BUILD_PKGS && \
  rpm -V $RUNTIME_PKGS && \
  yum clean all

ADD configs.d/ /etc/fluent/configs.d/
ADD out_syslog_buffered.rb out_syslog.rb out_rawtcp.rb /etc/fluent/plugin/
ADD parser_viaq_docker_audit.rb viaq_docker_audit.rb /etc/fluent/plugin/
ADD run.sh generate_syslog_config.rb ${HOME}/
ADD lib/generate_throttle_configs/lib/*.rb ${HOME}/
ADD lib/filter_parse_json_field/lib/*.rb /etc/fluent/plugin/
ADD lib/filter_elasticsearch_genid_ext/lib/filter_elasticsearch_genid_ext.rb /etc/fluent/plugin/

RUN mkdir -p /etc/fluent/configs.d/{dynamic,user} && \
    chmod 777 /etc/fluent/configs.d/dynamic && \
    ln -s /etc/fluent/configs.d/user/fluent.conf /etc/fluent/fluent.conf

ADD vendored_gem_src/ ${HOME}/vendored_gem_src/
ADD install-gems.sh *.patch.sh *.patch ${HOME}/vendored_gem_src/
RUN cd ${HOME}/vendored_gem_src/ && ./install-gems.sh && cd / && rm -rf ${HOME}/vendored_gem_src/

RUN BUILD_PKGS="make gcc-c++ libffi-devel \
                autoconf automake libtool m4 \
                redhat-rpm-config" && \
    yum remove -y $BUILD_PKGS

COPY utils/** /usr/local/bin/

WORKDIR ${HOME}

CMD ["sh", "run.sh"]

LABEL io.k8s.display-name=Fluentd

LABEL \
        io.k8s.description="Fluentd container for collecting of container logs" \
        com.redhat.component="logging-fluentd-container" \
        vendor="Red Hat" \
        name="openshift3/logging-fluentd" \
        License="GPLv2+" \
        io.k8s.display-name="Fluentd" \
        version="v3.10.0" \
        architecture="x86_64" \
        release="0.56.0.0" \
        io.openshift.tags="logging,elk,fluentd"

