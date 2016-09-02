sed -i "s/es_host/$ES_HOST/" ${KIBANA_HOME}/config/kibana.yml
sed -i "s/es_port/$ES_PORT/" ${KIBANA_HOME}/config/kibana.yml

${KIBANA_HOME}/bin/kibana
