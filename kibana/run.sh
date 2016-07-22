#!/bin/sh
set -euo pipefail

sed -i "s/es_host/$ES_HOST/" /opt/app-root/src/config/kibana.yml
sed -i "s/es_port/$ES_PORT/" /opt/app-root/src/config/kibana.yml

exec kibana
