# Kopf plugin in Origin Aggregated Logging
This repository contains documentation and artifacts necessary for deploying [Kopf](https://github.com/lmenezes/elasticsearch-kopf) in the [Origin Aggregated Logging](https://github.com/openshift/origin-aggregated-logging) project.
The AOL stack is expected to be already running.

### Installation
Deploy Kopf with the template:
```
oc create -f logging-es-kopf-template.yaml
oc new-app --template=logging-es-kopf -p KOPF_SECURE_URL=<your_kopf_url>
# enter KOPF_SECURE_URL without the 'https://' prefix
```
This deploys all of the necessary artifacts, with sensible default values.

Now, a new pod has been created in the `logging` project and Kopf is available
under `KOPF_SECURE_URL`. The pod consists of two containers:
1. Oauth proxy, that authenticates users against OpenShift API server
2. `httpd` image, that serves Kopf's www content

If you need a customized deployment, check out the available parameters in the
template.

### Troubleshoot
```
oc describe pod <logging-es-kopf-pod-name>
oc logs -c logging-es-kopf <logging-es-kopf-pod-name>
oc logs -c logging-es-kopf-auth-proxy <logging-es-kopf-pod-name>
```
