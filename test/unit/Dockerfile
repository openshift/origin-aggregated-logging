FROM centos/ruby-25-centos7:latest
MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

ENV FLUENTD_VERSION=1.0 \
    WORKDIR=/fluentd/lib

WORKDIR ${WORKDIR}

COPY fluentd/lib ${WORKDIR}
RUN scl enable rh-ruby25 -- gem install bundler --no-ri --no-doc
RUN for d in $(ls $WORKDIR); do \
      pushd ${d}; \
        export GEM_HOME=vendor ;\
        scl enable rh-ruby25 -- bundle install ;\
        scl enable rh-ruby25 -- bundle exec rake test ; \
      popd ; \
    done
