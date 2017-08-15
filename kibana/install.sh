chmod -R 755 ${KIBANA_HOME}/installedPlugins/origin-kibana

# Kibana starts up slowly because it tries to optimize and cache bundles
# so we start it up as part of install and then stop it
mv ${KIBANA_HOME}/config/kibana.yml ${KIBANA_HOME}/config/hidden_kibana.yml
touch ${KIBANA_HOME}/config/kibana.yml

${KIBANA_HOME}/bin/kibana > ${KIBANA_HOME}/kibana.out &
pid=$!

until [ -n "$(grep 'Optimization of bundles for kibana and statusPage complete' ${KIBANA_HOME}/kibana.out)" ]; do
  sleep 1
done
kill $pid

rm ${KIBANA_HOME}/kibana.out
rm ${KIBANA_HOME}/config/kibana.yml
mv ${KIBANA_HOME}/config/hidden_kibana.yml ${KIBANA_HOME}/config/kibana.yml
chmod -R og+w ${HOME}
chmod -R og+rw ${KIBANA_HOME}
