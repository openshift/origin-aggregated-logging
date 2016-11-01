FROM centos:centos7

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

# by default, run the curator cron job at midnight UTC every night, and delete
# indices older than 31 days old
ENV HOME=/opt/app-root/src \
    ES_HOST=localhost \
    ES_PORT=9200 \
    ES_CA=/etc/curator/keys/ca \
    ES_CLIENT_CERT=/etc/curator/keys/cert \
    ES_CLIENT_KEY=/etc/curator/keys/key \
    CURATOR_CONF_LOCATION=/etc/curator/settings/config.yaml \
    CURATOR_DEFAULT_DAYS=31 \
    CURATOR_RUN_HOUR=0 \
    CURATOR_RUN_MINUTE=0 \
    CURATOR_RUN_TIMEZONE=UTC \
    CURATOR_LOG_LEVEL=ERROR \
    CURATOR_SCRIPT_LOG_LEVEL=INFO \
    CURATOR_VER=3.5.1

LABEL io.k8s.description="Curator elasticsearch container for elasticsearch deletion/archival" \
  io.k8s.display-name="Curator ${CURATOR_VER}" \
  io.openshift.tags="logging,elk,elasticsearch,curator"

ADD run_cron.py install.sh run.sh ${HOME}/
RUN ${HOME}/install.sh

WORKDIR ${HOME}
USER nobody
CMD ["sh", "run.sh"]
