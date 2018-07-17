FROM alpine:3.6

RUN adduser -D cluster-logging-operator
USER cluster-logging-operator

ADD tmp/_output/bin/cluster-logging-operator /usr/local/bin/cluster-logging-operator
