FROM rhel7:7-released

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

# by default, run the curator cron job at midnight UTC every night, and delete
# indices older than $CURATOR_DEFAULT_DAYS days old
ENV HOME=/opt/app-root/src \
    ES_HOST=localhost \
    ES_PORT=9200 \
    ES_CA=/etc/curator/keys/ca \
    ES_CLIENT_CERT=/etc/curator/keys/cert \
    ES_CLIENT_KEY=/etc/curator/keys/key \
    CURATOR_CONF_LOCATION=/etc/curator/settings/config.yaml \
    CURATOR_DEFAULT_DAYS=31 \
    CURATOR_RUN_HOUR=3 \
    CURATOR_RUN_MINUTE=30 \
    CURATOR_RUN_TIMEZONE=UTC \
    CURATOR_LOG_LEVEL=ERROR \
    CURATOR_SCRIPT_LOG_LEVEL=INFO \
    CURATOR_VER=3.5.0-2 \
    CURATOR_TIMEOUT=300

RUN yum-config-manager --enable rhel-7-server-ose-3.8-rpms \
                       --enable rhel-7-server-extras-rpms && \
    INSTALL_PKGS="elastic-curator-${CURATOR_VER}.el7 \
                  PyYAML \
                  python-crontab \
                  python-setuptools \
                  pytz" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all

COPY src/* ${HOME}/

RUN mkdir -p $(dirname "$CURATOR_CONF_LOCATION") && \
    touch ${CURATOR_CONF_LOCATION} && \
    chmod -R u+x ${HOME} && \
    chgrp -R 0 ${HOME} && \
    chmod -R g=u ${HOME}

WORKDIR ${HOME}
USER 1001
CMD ["python", "-u", "run_cron.py"]

LABEL \
        io.k8s.description="Curator elasticsearch container for elasticsearch deletion/archival" \
        com.redhat.component="logging-curator-docker" \
        vendor="Red Hat" \
        name="openshift3/logging-curator" \
        License="GPLv2+" \
        io.k8s.display-name="Curator 3.5.0-2" \
        version="v3.9.27" \
        architecture="x86_64" \
        release="1" \
        io.openshift.tags="logging,elk,elasticsearch,curator"

