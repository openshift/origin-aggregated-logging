FROM centos:centos7

MAINTAINER Eric Wolinetz <ewolinet@redhat.com>

EXPOSE 9200
EXPOSE 9300

ENV HOME=/opt/app-root/src \
  PATH=/opt/app-root/src/bin:/opt/app-root/bin:$PATH \
  JAVA_VER=1.8.0 \
  ES_VER=1.5.2

LABEL io.k8s.description="Elasticsearch container for allowing indexing and searching of aggregated logs" \
  io.k8s.display-name="Elasticsearch 1.5.2" \
  io.openshift.expose-services="9200:http, 9300:http" \
  io.openshift.tags="logging,elk,elasticsearch"

COPY elasticsearch.repo /etc/yum.repos.d/elasticsearch.repo

RUN rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch && \
  yum install -y -- setopt=tsflags=nodocs \
  java-1.8.0-openjdk \
  elasticsearch && \
  mkdir -p ${HOME}

RUN mkdir -p /usr/share/elasticsearch/config && \
  cp /etc/elasticsearch/* /usr/share/elasticsearch/config

#VOLUME /usr/share/elasticsearch/data

ADD *.sh /opt/app-root/src/
RUN sh /opt/app-root/src/initialize.sh
ADD *.yml /usr/share/elasticsearch/config/

RUN chmod -R og+w /usr/share/elasticsearch && \
  chmod -R og+w ${HOME}

WORKDIR ${HOME}

CMD ["sh", "/opt/app-root/src/run.sh"]