FROM registry.svc.ci.openshift.org/ocp/4.0:base

RUN yum-config-manager --enable rhel-7-server-ose-4.1-rpms && \
  INSTALL_PKGS="rsyslog rsyslog-elasticsearch \
    rsyslog-mmkubernetes rsyslog-mmjsonparse rsyslog-kafka \
    rsyslog-mmnormalize rsyslog-relp rsyslog-gssapi" && \
  yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
  rpm -V $INSTALL_PKGS && \
  yum clean all

ADD install.sh /bin/install.sh
ADD rsyslog.sh /bin/rsyslog.sh
ADD uninstall.sh /bin/uninstall.sh

CMD [ "/bin/rsyslog.sh" ]
