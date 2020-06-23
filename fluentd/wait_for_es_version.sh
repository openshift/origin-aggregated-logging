#! /bin/bash

if [ -f /opt/rh/rh-ruby25/enable ] ; then
  source /opt/rh/rh-ruby25/enable
fi

ruby wait_for_es_version.rb $@
