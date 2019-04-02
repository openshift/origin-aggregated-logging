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

## Required Headers
Kibana must whitelist the following variables in order to integrate with the Openshift Logging Stack:
* authorization
* x-forwarded-for
* x-proxy-remote-user

## Additional Customizations
Additional customizations for Kibana are added to the Openshift logging stack in the [openshift-elasticsearch-plugin](https://github.com/fabric8io/openshift-elasticsearch-plugin).

## Overriding the OKD logo
It is possible to override the styles by defining a stylesheet and mounting it into the Kibana DeploymentConfig:

Create an `overrides.css` file like:
```
.container-brand {
  background-image: url('data:image/jpeg;base64,/.....');
  margin-top: 3px;
  height: 25px;
  background-repeat: no-repeat;
  background-position-y: 5px;
  padding-bottom: 35px;
}

```
Create a configmap:`oc create configmap kibana-styles --from-file=overrides.css=<YOURFILE>`

Edit the deployment `oc edit dc/logging-kibana` and mount the configmap to the pod:
```
volumeMounts:
- configMap:
     name: logging-kibana
  name: kibana-styles
```
and volume to the `kibana` container:
```
volumes:
- mountPath: /etc/openshift/kibana/styles
  name: kibana-styles
  readOnly: true

```
Rollout a new version: `oc rollout latest dc/logging-kibana`

**Note:** You may need to increase the memory to kibana in order for it to re-compile and optimize its assets.
