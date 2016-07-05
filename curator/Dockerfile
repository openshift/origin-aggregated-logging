FROM centos:centos7

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

# by default, run the curator cron job at midnight every night, and delete
# indices older than 30 days old
ENV HOME=/opt/app-root/src \
    ES_HOST=localhost \
    ES_PORT=9200 \
    CURATOR_CRON_MINUTE=0 \
    CURATOR_CRON_HOUR=0 \
    ES_CA=/etc/curator/keys/ca \
    ES_CLIENT_CERT=/etc/curator/keys/cert \
    ES_CLIENT_KEY=/etc/curator/keys/key \
    CURATOR_CONF_LOCATION=/etc/curator/settings/config.yaml \
    CURATOR_DEFAULT_DAYS=30 \
    CURATOR_RUN_HOUR=0 \
    CURATOR_RUN_MINUTE=0

LABEL io.k8s.description="Curator elasticsearch container for elasticsearch deletion/archival" \
  io.k8s.display-name="Curator 3.5.1" \
  io.openshift.tags="logging,elk,elasticsearch,curator"

ADD run.sh install.sh run_cron.py ${HOME}/
RUN ${HOME}/install.sh

WORKDIR ${HOME}
USER nobody
CMD ["sh", "run.sh"]
