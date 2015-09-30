FROM centos:centos7

MAINTAINER Eric Wolinetz <ewolinet@redhat.com>

ENV HOME=/opt/app-root/src \
  PATH=/opt/app-root/src/bin:/opt/app-root/bin:$PATH \
  RUBY_VERSION=2.0 \
  FLUENTD_VERSION=0.12.6 \
  GEM_HOME=/opt/app-root/src

LABEL io.k8s.description="Fluentd container for collecting of docker container logs" \
  io.k8s.display-name="Fluentd 0.12.6" \
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
  gem install fluentd fluent-plugin-kubernetes_metadata_filter fluent-plugin-elasticsearch fluent-plugin-flatten-hash

ADD out_elasticsearch*.rb /opt/app-root/src/gems/fluent-plugin-elasticsearch-1.0.0/lib/fluent/plugin/
ADD fluent.conf /etc/fluent/fluent.conf

WORKDIR ${HOME}

CMD ["fluentd"]
