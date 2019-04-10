FROM registry.svc.ci.openshift.org/ocp/4.2:base as builder

# get pkg list from rpmspec -q --buildrequires vendored_src/*/*.spec | sort -u
ADD install-builder-packages.sh /tmp
RUN cd /tmp && ./install-builder-packages.sh
ADD vendored_src/ /vendored_src/
ADD install-from-src.sh /vendored_src/
# liblognorm configure is hardcoded with certain versions of
# aclocal and automake - if certain files are out of date
# with respect to certain other files, make will attempt to
# reconfigure with versions that may not exist on the platform -
# so make sure the file dependencies are such that aclocal.m4
# is newer than its dependencies, and the other files are newer
# than aclocal.m4, so that make will not attempt to
# reconfigure anything
RUN cd /vendored_src && \
    touch liblognorm/liblognorm/aclocal.m4 && \
    touch liblognorm/liblognorm/Makefile.in && \
    touch liblognorm/liblognorm/configure && \
    touch liblognorm/liblognorm/config.h.in && \
    ./install-from-src.sh

ADD go/ /go/
RUN cd /go/src/github.com/soundcloud/rsyslog_exporter ; GOPATH=/go go build

FROM registry.svc.ci.openshift.org/ocp/4.2:base

COPY --from=builder /RPMS/ /RPMS/
COPY --from=builder /contents /contents
COPY --from=builder /go/src/github.com/soundcloud/rsyslog_exporter/rsyslog_exporter /usr/local/bin/

RUN yum -y install /RPMS/*.rpm cronie && \
    rm -rf /RPMS && \
    yum clean all

ADD install.sh /bin/install.sh
ADD rsyslog.sh /bin/rsyslog.sh
ADD uninstall.sh /bin/uninstall.sh
COPY utils/** /usr/local/bin/
RUN sed -i -e 's,\(session[ 	]*required[ 	]*pam_loginuid.so\),\#\1,' /etc/pam.d/crond

CMD [ "/bin/rsyslog.sh" ]
