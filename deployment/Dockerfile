FROM openshift/origin:latest

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

ENV BIN_DIR=/opt/deploy \
    SCRATCH_DIR=/etc/deploy \
    HOME=/etc/deploy \
    KUBECONFIG=/etc/deploy/.kubeconfig \
    WRITE_KUBECONFIG=1

RUN yum install -y java-1.8.0-openjdk openssl && yum clean all

RUN mkdir -p ${HOME} ${BIN_DIR} && chmod 777 ${HOME} && chmod 555 ${BIN_DIR}
COPY . ${BIN_DIR}
WORKDIR ${BIN_DIR}

VOLUME ${HOME}
ENTRYPOINT ["./run.sh"]
USER 1000
