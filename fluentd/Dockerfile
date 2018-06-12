FROM rhel7:7-released


MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

ENV DATA_VERSION=1.6.0 \
    FLUENTD_VERSION=0.12.42 \
    FLUENTD_ES=1.13.0-1 \
    FLUENTD_KUBE_METADATA=1.0.1-1 \
    FLUENTD_REWRITE_TAG=1.5.6-1 \
    FLUENTD_SECURE_FWD=0.4.5-2 \
    FLUENTD_SYSTEMD=0.0.9-1 \
    FLUENTD_VIAQ_DATA_MODEL=0.0.13 \
    FLUENTD_AUDIT_LOG_PARSER_VERSION=0.0.5 \
    FLUENTD_RECORD_MODIFIER=0.6.1 \
    GEM_HOME=/opt/app-root/src \
    HOME=/opt/app-root/src \
    PATH=/opt/app-root/src/bin:/opt/app-root/bin:/usr/libexec/fluentd/bin:$PATH \
    RUBY_VERSION=2.0 \
    OCP_OPERATIONS_PROJECTS='default openshift openshift-'

ARG TEST_REPO

RUN yum-config-manager --enable rhel-7-server-ose-3.10-rpms && \
  INSTALL_PKGS="fluentd-${FLUENTD_VERSION} \
                hostname \
                bc \
                iproute \
                rubygem-syslog_protocol \
                rubygem-fluent-mixin-config-placeholders \
                rubygem-fluent-plugin-elasticsearch \
                rubygem-fluent-plugin-flatten-hash \
                rubygem-fluent-plugin-kubernetes_metadata_filter \
                rubygem-fluent-plugin-record-modifier \
                rubygem-fluent-plugin-remote-syslog \
                rubygem-fluent-plugin-rewrite-tag-filter \
                rubygem-fluent-plugin-secure-forward \
                rubygem-fluent-plugin-systemd \
                rubygem-fluent-plugin-viaq_data_model" && \
  yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
  rpm -V $INSTALL_PKGS && \
  yum clean all

# uncomment if you want to try out test rpm builds
#ADD *.rpm /tmp/
#RUN yum -y install /tmp/*.rpm

ADD configs.d/ /etc/fluent/configs.d/
ADD filter_k8s_meta_for_mux_client.rb /etc/fluent/plugin/
ADD out_syslog_buffered.rb out_syslog.rb out_rawtcp.rb /etc/fluent/plugin/
ADD parser_viaq_docker_audit.rb viaq_docker_audit.rb /etc/fluent/plugin/
ADD run.sh generate_throttle_configs.rb generate_syslog_config.rb ${HOME}/

RUN mkdir -p /etc/fluent/configs.d/{dynamic,user} && \
    chmod 777 /etc/fluent/configs.d/dynamic && \
    ln -s /etc/fluent/configs.d/user/fluent.conf /etc/fluent/fluent.conf

COPY utils/** ${HOME}/utils

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

