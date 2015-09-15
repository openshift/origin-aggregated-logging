# Origin-Aggregated-Logging
The purpose of this repo is to create the components of the logging stack via Dockerfiles `cd hack; sh build-images.sh` and then deploy them via a single yaml file `oc create -f logging.yml`.

To use the mutual auth to connect to ElasticSearch you will need to create a JKS keychain and truststore for Elasticsearch, and unencrypted certificates and pkeys for Fluentd and Kibana.  The script hack/ssl/generateExampleKeys.sh will do this for you.  Then, you will need to configure secrets so that the containers can use these keys, if you ran generateExampleKeys.sh you can then run hack/ssl/createSecrets.sh and it will create the secrets and add them to the default service account.

You will also need to update the value of the 'K8S_HOST_URL' variable in the logging.yml template to be the value of the host ip/dname where your Kubernetes api is available at.
To allow fluentd to list all pods in the cluster, you will need to update the role of your service account.  Assuming you are using system:serviceaccount:default:default you can use the following command.  Please note this is not recommended for Production at this time.
```
oadm policy add-cluster-role-to-user cluster-reader system:serviceaccount:default:default
```

To ready your Persistant Volume Claims, you will need to create /tmp/data01 on your host node and ensure it has permissions 777. `mkdir -p /tmp/data01; chmod -R 777 /tmp/data01`.
Once that is created you can use the template `volume.yml` to create your Persistant Volume and then `pvc.yml` to create the Persistant Volume Claim that is used in `logging.yml`.

At this point you can create the stack using logging.yml.


## Operations logging scenario
The logging stack can be configured to send operations logs to a second Elasticsearch cluster.  The operations logs are sourced from syslog and the openshift* and default namespaces.  In this configuration a single Fluentd pod is able to service both these clusters by specifying the location of the cluster to contain application logs (non-operations) with the environment variables ES_HOST and ES_PORT and the location of the cluster to contain operations logs with the environment variable OPS_HOST and OPS_PORT.

The `ops-logging.yml` template file has been written in a way that it will create two different Elasticsearch clusters (one for application logs and one for operations logs), two Kibana clusters (one for each Elasticsearch cluster), the services for all the aformentioned clusters, and a Fluentd pod correctly configured to split up logs to both clusters.