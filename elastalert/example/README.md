You'll need to build the image and push to the registry.

Use elastalert-dev.yaml to create an imagestream and buildconfig
for remote building.

    oc process -p LOGGING_FORK_URL=https://github.com/myrepo/origin-aggregated-logging \
      -p LOGGING_FORK_BRANCH=mybranch -f elastalert-dev.yaml | oc create -f -

Create the secret elastalert-secrets from the elasticsearch secret -
you'll need the admin cert, key, and ca cert

    oc extract secret/elasticsearch --to=.
    mv admin-cert client.crt
    mv admin-key client.key
    mv admin-ca ca.crt
    rm elasticsearch.key logging-es.crt logging-es.key elasticsearch.crt
    oc create secret generic elastalert-secrets --from-file=.

Create the elastalert-config configmap from the openshift-logging.yaml
config file:

    oc create configmap elastalert-config --from-file=openshift-logging.yaml

Create the elastalert-rules-rules configmap from example/rules/sample.yaml.  Edit the
file if you want to match on something else.

    oc create configmap elastalert-rules-rules --from-file=sample.yaml=example/rules/sample.yaml

Create the elastalert-rules-imports configmap from example/rules/sample.yaml

    oc create configmap elastalert-rules-imports --from-file=sample.yaml=example/rules/sample.yaml

Create the elastalert pod

    oc process -f elastalert-template.yml | oc create -f -

    oc logs -f elastalert

Add a record to Elasticsearch that matches index `.operations.*` and
`systemd.u.SYSLOG_IDENTIFIER=myuniqueid`.  If you wait a couple of minutes, you should
see the record printed to the elastalert pod log.
