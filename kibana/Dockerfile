FROM ubi7/nodejs-10:latest

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 5601

ENV ELASTICSEARCH_URL=https://elasticsearch.openshift-logging.svc.cluster.local:9200 \
    HOME=/opt/app-root/src  \
    KIBANA_CONF_DIR=${HOME}/config \
    KIBANA_VERSION=6.8.1 \
    NODE_ENV=production \
    RELEASE_STREAM=prod \
    container=oci \
    NODE_ENV=production \
    NODE_PATH=/opt/rh/rh-nodejs10/root/usr/bin

ARG LOCAL_REPO

USER 0

COPY vendored_tar_src/kibana-oss-6.8.1 ${HOME}/
COPY vendored_tar_src/opendistro_security_kibana_plugin-0.10.0.4/ ${HOME}/plugins/opendistro_security_kibana_plugin-0.10.0.4/
COPY vendored_tar_src/handlebars/ ${HOME}/node_modules/handlebars/
COPY vendored_tar_src/minimist/ ${HOME}/node_modules/minimist/
COPY lib/openshift_logging_plugin/ ${HOME}/plugins/openshift_logging_plugin/

RUN chmod -R og+w ${HOME}/
ADD probe/ /usr/share/kibana/probe/
ADD kibana.yml ${KIBANA_CONF_DIR}/
ADD run.sh module_list.sh utils ${HOME}/
RUN sed -i -e 's/"node":.*/"node": "'$(${NODE_PATH}/node --version | sed 's/v//')'"/' package.json && \
    mkdir -p node && \
    ln -s ${NODE_PATH} node/bin
RUN bin/kibana --optimize

WORKDIR ${HOME}
CMD ["./run.sh"]
