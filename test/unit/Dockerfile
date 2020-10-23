FROM centos/ruby-25-centos7:latest
MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

ENV FLUENTD_VERSION=1.0 \
    WORKDIR=/fluentd/lib

ENTRYPOINT /tmp/run.sh
RUN whoami
RUN scl enable rh-ruby25 -- gem install bundler --no-ri --no-doc
WORKDIR ${WORKDIR}
RUN echo HERE1
RUN ls -ld /fluentd || true
RUN echo HERE2
RUN ls -l /fluentd || true
RUN echo HERE3
RUN ls -l /fluentd/lib || true
RUN echo HERE4
RUN mkdir -p ${WORKDIR}
RUN echo HERE5
RUN ls -ld ${WORKDIR}
RUN echo HERE6
RUN ls -l /fluentd
RUN echo HERE7
RUN ls -l ${WORKDIR} 
RUN echo HERE8
RUN ls -ld ${WORKDIR} 
COPY test/unit/run.sh /tmp/
COPY fluentd/lib ${WORKDIR}
RUN for d in $(ls $WORKDIR) ; do \
    pushd ${d} ; \
        export GEM_HOME=vendor ; \
        scl enable rh-ruby25 -- bundle install ; \
    popd ; \
    done
RUN /tmp/run.sh
