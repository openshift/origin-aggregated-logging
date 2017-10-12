FROM rhel7:7-released

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

ENV DATA_VERSION=1.6.0 \
    FLUENTD_VERSION=0.12.39 \
    FLUENTD_ES=1.9.5.1-1 \
    FLUENTD_FLATTEN_HASH=0.4.0-1 \
    FLUENTD_KUBE_METADATA=0.29.0-1 \
    FLUENTD_REWRITE_TAG=1.5.6-1 \
    FLUENTD_SECURE_FWD=0.4.5-2 \
    FLUENTD_SYSTEMD=0.0.8-1 \
    FLUENTD_VIAQ_DATA_MODEL=0.0.11-1 \
    FLUENTD_AUDIT_LOG_PARSER_VERSION=0.0.4 \
    GEM_HOME=/opt/app-root/src \
    HOME=/opt/app-root/src \
    PATH=/opt/app-root/src/bin:/opt/app-root/bin:$PATH \
    RUBY_VERSION=2.0

LABEL io.k8s.description="Fluentd container for collecting of docker container logs" \
      io.k8s.display-name="Fluentd ${FLUENTD_VERSION}" \
      io.openshift.tags="logging,elk,fluentd" \
      com.redhat.component=logging-fluentd-docker \
      name="openshift3/logging-fluentd" \
      version="v3.7.0" \
      release="1" \
      architecture=x86_64

RUN yum-config-manager --enable rhel-7-server-ose-3.7-rpms && \
  INSTALL_PKGS="fluentd-${FLUENTD_VERSION} \
                hostname \
                bc \
                iproute \
                rubygem-fluent-plugin-elasticsearch \
                rubygem-fluent-plugin-flatten-hash \
                rubygem-fluent-plugin-kubernetes_metadata_filter \
                rubygem-fluent-plugin-rewrite-tag-filter \
                rubygem-fluent-plugin-secure-forward \
                rubygem-fluent-plugin-systemd \
                rubygem-fluent-plugin-viaq_data_model \
                rubygem-fluent-plugin-remote-syslog" && \
  yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
  rpm -V $INSTALL_PKGS && \
  yum clean all

ADD configs.d/ /etc/fluent/configs.d/
ADD filter_k8s_meta_for_mux_client.rb /etc/fluent/plugin/
ADD run.sh generate_throttle_configs.rb generate_syslog_config.rb ${HOME}/
COPY lib/fluent-plugin-viaq_docker_audit_log_parser-${FLUENTD_AUDIT_LOG_PARSER_VERSION}.gem /tmp
RUN  gem install -N --conservative --minimal-deps --no-ri --no-doc \
       /tmp/fluent-plugin-viaq_docker_audit_log_parser-${FLUENTD_AUDIT_LOG_PARSER_VERSION}.gem && \
     rm /tmp/*.gem

RUN mkdir -p /etc/fluent/configs.d/{dynamic,user} && \
    chmod 777 /etc/fluent/configs.d/dynamic && \
    ln -s /etc/fluent/configs.d/user/fluent.conf /etc/fluent/fluent.conf

WORKDIR ${HOME}

CMD ["sh", "run.sh"]
