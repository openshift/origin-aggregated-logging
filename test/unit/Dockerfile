FROM centos/ruby-25-centos7:latest
MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

ENV FLUENTD_VERSION=1.0 \
    WORKDIR=/fluentd/lib

USER 0
ENTRYPOINT /tmp/run.sh
ENV GEM_HOME=/tmp/vendor
RUN scl enable rh-ruby25 -- gem install bundler --no-ri --no-doc
WORKDIR ${WORKDIR}
COPY test/unit/run.sh /tmp/
COPY fluentd/lib ${WORKDIR}
RUN for d in $(ls $WORKDIR) ; do \
    pushd ${d} ; \
        scl enable rh-ruby25 -- bundle install ; \
    popd ; \
    done
RUN scl enable rh-ruby25 -- /tmp/run.sh
