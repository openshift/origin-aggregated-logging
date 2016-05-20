FROM centos:centos7

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

ENV HOME=/opt/app-root/src \
  PATH=/opt/app-root/src/bin:/opt/app-root/bin:$PATH \
  RUBY_VERSION=2.0 \
  FLUENTD_VERSION=0.12.23 \
  GEM_HOME=/opt/app-root/src \
  THROTTLE_CONF_LOCATION=/etc/throttle-settings

LABEL io.k8s.description="Fluentd container for collecting of docker container logs" \
  io.k8s.display-name="Fluentd ${FLUENTD_VERSION}" \
  io.openshift.expose-services="9200:http, 9300:http" \
  io.openshift.tags="logging,elk,fluentd"

RUN rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
  yum install -y --setopt=tsflags=nodocs \
  gcc-c++ \
  ruby \
  ruby-devel \
  libcurl-devel \
  make && \
  mkdir -p ${HOME} && \
  gem install --no-rdoc --no-ri fluentd:${FLUENTD_VERSION} fluent-plugin-kubernetes_metadata_filter fluent-plugin-elasticsearch fluent-plugin-flatten-hash && \
  mkdir -p ${THROTTLE_CONF_LOCATION} && \
  touch ${THROTTLE_CONF_LOCATION}/settings

ADD fluent.conf /etc/fluent/fluent.conf
ADD configs.d/ /etc/fluent/configs.d/
ADD run.sh generate_throttle_configs.rb \
    fluentd_es_copy_config.conf fluentd_es_ops_copy_config.conf \
    ${HOME}/

WORKDIR ${HOME}

CMD ["sh", "run.sh"]
