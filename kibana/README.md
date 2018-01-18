# Kibana

This repo provides the Openshift Origin customization to [Kibana](https://www.elastic.co/products/kibana).  The primary differences are:

* User Interface skinning based on [origin-kibana](https://github.com/openshift/origin-kibana) plugin
* Configuration overrides via [environment variables](https://www.elastic.co/guide/en/kibana/master/_configuring_kibana_on_docker.html) similar to that provided by the official Kibana Docker image

## Configuration Modifications
Modifying Kibana's configuration is possible by setting an environment value that corresponds to a config key.  This is generally accomplished by making all values uppercase and replacing the dots with underscores.  Examples of possible changes are listed below:

|Environment Variable | Kibana Config Key |
|------|------|
|`ELASTICSEARCH_URL` | `elasticsearch.url`|
|`ELASTICSEARCH_REQUESTTIMEOUT`|`elasticsearch.requestTimeout`|
|`KIBANA_DEFAULTAPPID`|`kibana.defaultAppId`|



## Additional Customizations
Additional customizations for Kibana are added to the Openshift logging stack in the [openshift-elasticsearch-plugin](https://github.com/fabric8io/openshift-elasticsearch-plugin).