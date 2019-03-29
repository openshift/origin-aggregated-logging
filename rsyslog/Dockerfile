FROM registry.svc.ci.openshift.org/ocp/4.0:base as builder

# get pkg list from rpmspec -q --buildrequires vendored_src/*/*.spec | sort -u
ADD install-builder-packages.sh /tmp
RUN cd /tmp && ./install-builder-packages.sh
ADD vendored_src/ /vendored_src/
ADD install-from-src.sh /vendored_src/
RUN cd /vendored_src && ./install-from-src.sh

FROM registry.svc.ci.openshift.org/ocp/4.0:base

COPY --from=builder /RPMS/ /RPMS/

RUN yum -y install /RPMS/*.rpm && \
    rm -rf /RPMS && \
    yum clean all

ADD install.sh /bin/install.sh
ADD rsyslog.sh /bin/rsyslog.sh
ADD uninstall.sh /bin/uninstall.sh

CMD [ "/bin/rsyslog.sh" ]
