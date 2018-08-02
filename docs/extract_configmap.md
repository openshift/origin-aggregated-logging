# Creating a Configmap
Sometimes it is advantageous to add files to a configmap to override those which are built into the image.  This is useful for specific customizations that are not provided with the product or when it is possible to resolve issues unrelated to compiled code changes.  Following is an example of how one might extract the Elasticsearch index templates to a configmap in order to provide an alias to each index.

**NOTE:**  The steps which add volumes to each deploymentconfig will need to be performed after each upgrade since they are not preserved by the installation and upgrade process.

1. Retrieve the source templates from `https://github.com/openshift/origin-aggregated-logging/tree/release-X.Y/elasticsearch/index_templates`
   where X.Y is your OpenShift release major.minor version e.g. release-3.11 for OpenShift 3.11

  ```
  $ wget https://raw.githubusercontent.com/openshift/origin-aggregated-logging/release-1.5/elasticsearch/index_templates/com.redhat.viaq-openshift-project.template.json
  $ wget https://raw.githubusercontent.com/openshift/origin-aggregated-logging/release-1.5/elasticsearch/index_templates/com.redhat.viaq-openshift-operations.template.json
  ```

2. Edit each file to provide the changes (e.g. alias all indicies)
  ```
  {
  "aliases": {
    ".all" : {}
  },
  "mappings": {
    "_default_": {
      "_meta": {
        "version": "2016.10.12.0"
      },
      "date_detection": false,
      "dynamic_templates": [
        {
    ...
  ```

3. Create the configmap
```
$ oc create -n $LOGGING_NAMESPACE configmap index-templates --from-file=$DIR
```
  where `$LOGGING_NAMESPACE` is typically `openshift-logging`(`logging` for older releases)
  Use `oc get projects` to see which one you have. If you have both, use `openshift-logging`.

  **NOTE:** This method can also be used to add custom Elasticsearch index templates by adding index template .json files to `$DIR`.

4. Mount the configmap into each deploymentconfig
```
$ oc edit -n $LOGGING_NAMESPACE $ELASTICSEARCH_DC
  ...
volumeMounts:
- mountPath: /usr/share/elasticsearch/index_templates
  name: index-templates
  ...
volumes:
- configMap:
    defaultMode: 420
    name: index-templates
  ...
```
  `$ELASTICSEARCH_DC` is in the form `dc/logging-es-xxxxx` - Use `oc get -n $LOGGING_NAMESPACE dc` to find the name of your Elasticsearch dc

5. Follow the formal [procedure for rolling out new deployments](https://docs.openshift.com/container-platform/3.9/install_config/aggregate_logging.html#elasticsearch-rolling-restart)
