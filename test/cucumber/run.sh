#!/bin/sh
HOME=/opt/app/src
# By default skip any tagged with '@skip'
if [ -n "${TAGS}" ] ; then
  TAGS="--tags ${TAGS}"
fi
OPTS="--tags ~@skip ${TAGS:-}"

PATH=/usr/bin:${PATH} GEM_HOME=./vendor bundle exec cucumber $OPTS
