FROM centos:centos7

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

ENV HOME=/opt/app-root/src \
  PATH=/opt/app-root/src/bin:/opt/app-root/bin:$PATH \
  RUBY_VERSION=2.0 \
  FLUENTD_VERSION=0.12.31 \
  GEM_HOME=/opt/app-root/src \
  DATA_VERSION=1.6.0

LABEL io.k8s.description="Fluentd container for collecting of docker container logs" \
  io.k8s.display-name="Fluentd ${FLUENTD_VERSION}" \
  io.openshift.expose-services="9200:http, 9300:http" \
  io.openshift.tags="logging,elk,fluentd"

# activesupport version 5.x requires ruby 2.2
# iproute needed for ip command to get ip addresses
RUN rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    yum install -y --setopt=tsflags=nodocs \
      gcc-c++ \
      ruby \
      ruby-devel \
      libcurl-devel \
      make \
      iproute && \
    yum clean all
RUN mkdir -p ${HOME} && \
    gem install -N --conservative --minimal-deps \
      fluentd:${FLUENTD_VERSION} \
      'activesupport:<5' \
      fluent-plugin-kubernetes_metadata_filter \
      fluent-plugin-elasticsearch \
      'fluent-plugin-systemd:<0.1.0' \
      systemd-journal \
      fluent-plugin-rewrite-tag-filter \
      fluent-plugin-secure-forward \
      fluent-plugin-viaq_data_model

ADD configs.d/ /etc/fluent/configs.d/
ADD run.sh generate_throttle_configs.rb ${HOME}/

RUN mkdir -p /etc/fluent/configs.d/{dynamic,user} && \
    chmod 777 /etc/fluent/configs.d/dynamic && \
    ln -s /etc/fluent/configs.d/user/fluent.conf /etc/fluent/fluent.conf

WORKDIR ${HOME}
USER 0
CMD ["sh", "run.sh"]
