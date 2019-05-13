FROM fedora

MAINTAINER https://github.com/ViaQ/rsyslog-container

RUN dnf -y install rsyslog rsyslog-elasticsearch \
    rsyslog-mmkubernetes rsyslog-mmjsonparse rsyslog-kafka \
    rsyslog-mmnormalize rsyslog-relp rsyslog-gssapi \
    cronie \
    && dnf clean all

LABEL install="docker run --rm --privileged -v /:/host \
-e HOST=/host -e IMAGE=IMAGE -e NAME=NAME \
IMAGE /bin/install.sh"

LABEL uninstall="docker run --rm --privileged -v /:/host \
-e HOST=/host -e IMAGE=IMAGE -e NAME=NAME \
IMAGE /bin/uninstall.sh"

LABEL run="docker run -d --privileged --name NAME \
--net=host --pid=host \
-v /etc/pki/rsyslog:/etc/pki/rsyslog \
-v /etc/rsyslog.conf:/etc/rsyslog.conf \
-v /etc/sysconfig/rsyslog:/etc/sysconfig/rsyslog \
-v /etc/rsyslog.d:/etc/rsyslog.d \
-v /var/log:/var/log \
-v /var/lib/rsyslog:/var/lib/rsyslog \
-v /run/log/journal:/run/log/journal \
-v /run:/run \
-v /etc/machine-id:/etc/machine-id \
-v /etc/localtime:/etc/localtime \
-e IMAGE=IMAGE -e NAME=NAME \
--restart=always IMAGE /bin/rsyslog.sh"

ADD install.sh /bin/install.sh
ADD rsyslog.sh /bin/rsyslog.sh
ADD uninstall.sh /bin/uninstall.sh
COPY utils/** /usr/local/bin/

CMD [ "/bin/rsyslog.sh" ]
