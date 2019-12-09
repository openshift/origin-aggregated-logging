FROM centos/ruby-25-centos7:latest
MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

ENV FLUENTD_VERSION=1.0 \
    WORKDIR=/fluentd/lib

ENTRYPOINT /tmp/run.sh
RUN scl enable rh-ruby25 -- gem install bundler --no-ri --no-doc
WORKDIR ${WORKDIR}
COPY test/unit/run.sh /tmp/
COPY fluentd/lib ${WORKDIR}
RUN for d in $(ls $WORKDIR) ; do \
    pushd ${d} ; \
        export GEM_HOME=vendor ; \
        scl enable rh-ruby25 -- bundle install ; \
    popd ; \
    done
RUN /tmp/run.sh
