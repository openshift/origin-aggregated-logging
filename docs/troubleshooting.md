# Troubleshooting

Following is troubleshooting information for a number of commonly identified issues with cluster logging deployments:

# All Components
## Deployment fails, RCs scaled to 0

When a deployment is performed, if it does not successfully bring up an
instance before a ten-minute timeout, it will be considered failed and
scaled down to zero instances. `oc get pods` will show a deployer pod
with a non-zero exit code, and no deployed pods, e.g.:

    NAME                           READY     STATUS             RESTARTS   AGE
    logging-es-2e7ut0iq-1-deploy   1/1       ExitCode:255       0          1m

(In this example, the deployer pod name for an Elasticsearch deployment is shown;
this is from ReplicationController `logging-es-2e7ut0iq-1` which is a deployment
of DeploymentConfig `logging-es-2e7ut0iq`.)

Deployment failure can happen for a number of transitory reasons, such as
the image pull taking too long, or nodes being unresponsive. Examine the
deployer pod logs for possible reasons; but often you can redeploy:

    $ oc deploy --latest logging-es-2e7ut0iq

Or you may be able to scale up the existing deployment:

    $ oc scale --replicas=1 logging-es-2e7ut0iq-1

If the problem persists, examine pod, events, and systemd unit
logs to determine the source of the problem.

## Image pull fails

If you specify an `openshift_logging_image_prefix` that results in images being defined that don't exist,
you will receive a corresponding error message:

    NAME                     READY     STATUS                                                                                       RESTARTS   AGE
    logging-fluentd-1ub9k    0/1       Error: image registry.access.redhat.com:5000/openshift3logging-fluentd:latest not found      0          1m

In this example, for the intended image name
`registry.access.redhat.com:5000/openshift3/logging-fluentd:latest`
the `openshift_logging_image_prefix` needed a trailing `/`.

Update the inventory file and follow the `openshift-ansible` instructions
to re-run the `openshift_logging` role.

## Can't resolve kubernetes.default.svc.cluster.local

This internal alias for the master should be resolvable by the included
DNS server on the master. Depending on your platform, you can run the `dig` command (perhaps in a container) against the master to
check whether this is the case:

    master$ dig kubernetes.default.svc.cluster.local @localhost
    [...]
    ;; QUESTION SECTION:
    ;kubernetes.default.svc.cluster.local. IN A

    ;; ANSWER SECTION:
    kubernetes.default.svc.cluster.local. 30 IN A   172.30.0.1

Older versions of OKD did not automatically define this internal
alias for the master. You may need to upgrade your cluster in order to
use aggregated logging. If your cluster is up to date, there may be
a problem with your pods reaching the SkyDNS resolver at the master,
or it could have been blocked from running. You must resolve this
problem before deploying again.

## Can't connect to the master or services

If DNS resolution does not return at all or the address cannot be
connected to from within a pod (e.g. the fluentd pod), this generally
indicates a system firewall/network problem and should be debugged
as such.

## ElasticSearch
### Elasticsearch deployments never succeed and rollback to previous version
This situation typically manifests itself on OKD clusters deployed on AWS.  Describing the Elasticsearch pods typically reveal issues re-attaching the pods
storage:
```
$ oc describe pod $ES_POD
```
Consider patching each Elasticsearch DeploymentConfig to allow more time for AWS to make the storage available:
```
oc patch dc $DC -p '{"spec":{"strategy":{"recreateParams": {"timeoutSeconds":1800}}}}'
```
### Searchguard index remains red
This is a known issue related to upgrade and moving to a single SG index per
cluster instead of one per DeploymentConfig.  The explain API is used to discover the reason and removing the index to node assignment is required:
```
oc -c elasticsearch exec ${pod} -- es_util --query=".searchguard/_settings" -XPUT -d "{\"index.routing.allocation.include._name\": \"\"}"
```
### Elasticsearch pods never become ready
This is known issue when the initialization and seeding process fails which
can be from a red `.searchguard` index.
```
for p in $(oc get pods -l component=es -o jsonpath={.items[*].metadata.name}); do \
  oc exec -c elasticsearch $ES_POD -- touch /opt/app-root/src/init_failures;  \
done
```
### Elasticsearch performance degrades around 00:00 UTC
This situation is a result of Elasticsearch processing bulk index requests from all the nodes in the OKD cluster for
logs for the new day.  Creation of a significant number of new indices simultaneously can cause bulk index processing 
to slow down as it waits for all members of the cluster to become aware of each new index.  This
is likely to happen when there are many active projects (namespaces) in a cluster, since each projects has its own index.
```
apiVersion: v1
kind: Template
metadata:
  name: indices-precreate
objects:
- apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    name: precreate-indices
  rules:
  - apiGroups:
    - ""
    resources:
    - pods
    verbs:
    - list
    - get
  - apiGroups:
    - ""
    resources:
    - pods/exec
    verbs:
    - create
- apiVersion: rbac.authorization.k8s.io/v1
  kind: RoleBinding
  metadata:
    name: precreate-indices
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: Role
    name: precreate-indices
  subjects:
  - kind: ServiceAccount
    name: ${CRON_SERVICE_ACCOUNT}
    namespace: ${LOGGING_NAMESPACE}
- apiVersion: batch/v1beta1
  kind: CronJob
  metadata:
    name: precreate-indices
    labels:
       provider: openshift
       logging-infra: indices-precreate
  spec:
    schedule: "${CRON_SCHEDULE}"
    jobTemplate:
      spec:
        template:
          metadata:
            labels:
              provider: openshift
              logging-infra: indices-precreate
          spec:
            serviceAccount: ${CRON_SERVICE_ACCOUNT}
            serviceAccountName: ${CRON_SERVICE_ACCOUNT}
            containers:
            - name: cli
              image: ${CLI_IMAGE}
              command: ["/bin/bash", "-c"]
              args:
              - echo "Starting pre-create of indices for Cluster Logging Elasticsearch...";
                function finish {
                  rm -rf $TMPDIR;
                };
                trap finish EXIT;
                TMPDIR=$(mktemp -d);
                function task_wait_time_millis() {
                    oc exec -n ${LOGGING_NAMESPACE} -c elasticsearch $es_pod -- es_util --query="_cluster/health" < /dev/null | python -c 'import sys, json; print json.load(sys.stdin)["task_max_waiting_in_queue_millis"]';
                };
                TODAY=$(date "+%Y.%m.%d");
                TODAYSED=$(date "+%Y\\.%m\\.%d");
                TOMOR=$(date --date="12:00 tomorrow" "+%Y.%m.%d");
                es_pod=$(basename $(oc get pods -n ${LOGGING_NAMESPACE} -l component=${ES_COMPONENT_NAME} -o name | head -n 1));
                oc exec -n ${LOGGING_NAMESPACE} -c elasticsearch $es_pod -- indices | grep -E '^(green  open)' | grep -E 'project.|.operations.|.orphaned.' | sort -k 3 > $TMPDIR/all.lis;
                grep -F "$TODAY" $TMPDIR/all.lis | awk '{if ($7 > 0) { print $3 }}' > $TMPDIR/today.lis;
                grep -F "$TOMOR" $TMPDIR/all.lis | awk '{ print $3 }' > $TMPDIR/tomor.lis;
                sed "s/\.${TODAYSED}/.${TOMOR}/" $TMPDIR/today.lis > $TMPDIR/tomor-new.lis;
                cat $TMPDIR/tomor.lis $TMPDIR/tomor-new.lis | sort | uniq -c | grep -Ev "  2 (project\.|.operations.|.orphaned.)" | awk '{print $2}' | grep -F "$TOMOR" > $TMPDIR/create.lis;
                let total=$(wc -l $TMPDIR/create.lis | awk '{ print $1 }');
                if [ $total -eq 0 ]; then
                    echo "Exiting early. There is no reason to precreate any indices";
                    exit 0;
                fi;
                echo "Creating ${total} new indices...";
                function wait_for_low_task_queue {
                    mtwt=$(task_wait_time_millis);
                    if [ $mtwt -gt ${PENDING_WAIT_TIME_THRESHOLD_MILLIS} ]; then
                        while [ $mtwt -gt ${PENDING_WAIT_TIME_UPPER_LIMIT_MILLIS} ]; do
                            echo "    Waiting for 'task_max_waiting_in_queue_millis' to drop to one second or under";
                            sleep 5;
                            mtwt=$(task_wait_time_millis);
                        done
                    fi;
                };
                let cnt=0;
                while read idx; do
                    wait_for_low_task_queue;
                    let cnt=cnt+1;
                    echo "  creating ($cnt of $total) $idx ...";
                    oc exec -n ${LOGGING_NAMESPACE} -c elasticsearch $es_pod -- es_util --query=$idx -XPUT < /dev/null;
                done < $TMPDIR/create.lis
            restartPolicy: OnFailure
parameters:
- name: CLI_IMAGE
  value: openshift/origin-cli:latest
  description: "The image to use to execute the script"
- name: CRON_SCHEDULE
  value: "0 4,8,12,16,20 * * *"
  description: "The schedule to to pre-create indices. Defaults to every 4 hours except midnight"
- name: PENDING_WAIT_TIME_THRESHOLD_MILLIS
  value: "30000"
  description: "The lower threshold of pending task queue wait time before proceeding"
- name: PENDING_WAIT_TIME_UPPER_LIMIT_MILLIS
  value: "1000"
  description: "The upper bound for pending tasks in millis"
- name: LOGGING_NAMESPACE
  value: openshift-logging
  description: "The logging namespace"
- name: CRON_SERVICE_ACCOUNT
  value: aggregated-logging-elasticsearch
  description: "The serviceaccount name"
- name: ES_COMPONENT_NAME
  value: es
  description: "The component label for Elasticsearch"

```
Create the `CronJob` by processing and applying the template:
```
$ oc process -f precreate-indices.yml  | oc apply -f -
```

See the [Kubernetes documentation](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/#suspend)  about how
to suspend this job if necessary.

## Fluentd
### Fluentd is holding onto deleted journald files that have been rotated
This [issue](https://bugzilla.redhat.com/show_bug.cgi?id=1664744) causes `/var/log` to fill up with file handles of 
deleted journald files.  The only known solution at this time is to periodically cycle Fluentd.  An OKD `CronJob` can be added to perform this function, for example, by checking every 10 minutes the amount of available space to fluentd:
```
apiVersion: v1
kind: Template
metadata:
  name: fluentd-reaper
objects:
- apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    name: fluentd-reaper
  rules:
  - apiGroups:
    - ""
    resources:
    - pods
    verbs:
    - delete
  - apiGroups:
    - ""
    resources:
    - pods/exec
    verbs:
    - create
- apiVersion: rbac.authorization.k8s.io/v1
  kind: RoleBinding
  metadata:
    name: fluentd-reaper
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: Role
    name: fluentd-reaper
  subjects:
  - kind: ServiceAccount
    name: aggregated-logging-fluentd
    namespace: ${LOGGING_NAMESPACE}
- apiVersion: batch/v1beta1
  kind: CronJob
  metadata:
    name: fluentd-reaper
    labels:
       provider: openshift
       logging-infra: fluentd-reaper
  spec:
    schedule: "${REAP_SCHEDULE}"
    jobTemplate:
      spec:
        template:
          metadata:
            labels:
              provider: openshift
              logging-infra: fluentd-reaper
          spec:
            serviceAccount: aggregated-logging-fluentd
            serviceAccountName: aggregated-logging-fluentd
            containers:
            - env:
              - name: REAP_THRESHOLD
                value: "${REAP_THRESHOLD}"
              name: cli
              image: ${CLI_IMAGE}
              command: ["/bin/bash", "-c"]
              args:
                - echo "Checking fluentd pods for space issues on /var/log...";
                  pods=$(oc get pods -l component=fluentd -o jsonpath={.items[*].metadata.name});
                  for p in $pods; do
                    echo "Checking $p...";
                    if ! $(oc get pod $p | grep Running >> /dev/null)  ; then
                      echo "$p as its not in a Running state. Skipping...";
                      continue;
                    fi;
                    space=$(oc exec -c fluentd-elasticsearch $p -- bash -c 'df --output=pcent /var/log | tail -1 | cut -d "%" -f1 | tr -d " "');
                    echo "Capacity $space";
                    if [ $space -gt ${REAP_THRESHOLD_PERCENTAGE} ] ; then
                      echo "Used capacity exceeds threshold. Deleting $p";
                      oc delete pod $p ;
                    fi;
                  done;
            restartPolicy: OnFailure
parameters:
- name: CLI_IMAGE
  value: openshift/origin-cli:latest
  description: "The image to use to execute the reaper script"
- name: REAP_THRESHOLD_PERCENTAGE
  value: "75"
  description: "The max capacity to allow for /var/log before restarting fluentd"
- name: REAP_SCHEDULE
  value: "*/30 * * * *"
  description: "The schedule to check for low disk capacity"
- name: LOGGING_NAMESPACE
  value: openshift-logging
  description: "The schedule to check for low disk capacity"


```
Create the `CronJob` by processing and applying the template:
```
$ oc process -f cron.yml  | oc apply -f -
```
**Note:** Modify the rolebinding serviceaccount namespace as needed (e.g. `logging` instead of `openshift-logging`)

See the [Kubernetes documentation](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/#suspend)  about how
to suspend this job if necessary.

## Kibana
### Looping login on Kibana

The experience here is that when you visit Kibana, it redirects you to
login. Then when you login successfully, you are redirected back to Kibana,
which immediately redirects back to login again.

The typical reason for this is that the OAuth2 proxy in front of Kibana
is supposed to share a secret with the master's OAuth2 server, in order
to identify it as a valid client. This problem likely indicates that
the secrets do not match (unfortunately nothing reports this problem
in a way that can be exposed). This can happen when you deploy logging
more than once (perhaps to fix the initial deployment) and the `secret`
used by Kibana is replaced while the master `oauthclient` entry to match
it is not.

You can do the following:

    $ oc delete oauthclient/kibana-proxy

Follow the `openshift-ansible` instructions to re-run the `openshift_logging` role.
This will replace the oauthclient and your next successful login should not loop.

### "error":"invalid\_request" on login

When you visit Kibana directly and it redirects you to login, you instead
receive an error in the browser like the following:

     {"error":"invalid_request","error_description":"The request is missing a required parameter,
      includes an invalid parameter value, includes a parameter more than once, or is otherwise malformed."}

The reason for this is a mismatch between the OAuth2 client and server.
The return address for the client has to be in a whitelist for the server to
securely redirect back after logging in; if there is a mismatch, then this
cryptic error message is shown.

As above, this may be caused by an `oauthclient` entry lingering from a
previous deployment, in which case you can replace it:

    $ oc delete oauthclient/kibana-proxy

Follow the `openshift-ansible` instructions to re-run the `openshift_logging` role.
This will replace the `oauthclient`. Return to the Kibana URL and try again.  

If the problem persists, then you may be accessing Kibana at
a URL that the `oauthclient` does not list. This can happen when, for
example, you are trying out logging on a vagrant-driven VirtualBox
deployment of OKD and accessing the URL at forwarded port 1443
instead of the standard 443 HTTPS port. Whatever the reason, you can
adjust the server whitelist by editing its `oauthclient`:

    $ oc edit oauthclient/kibana-proxy

This brings up a YAML representation in your editor, and you can edit
the redirect URIs accepted to include the address you are actually using.
After you save and exit, this should resolve the error.

### Kibana access shows 503 error

If everything is deployed but visiting Kibana results in a proxy
error, then one of the following things is likely to be the issue.

First, Kibana might not actually have any pods that are recognized
as running. If ElasticSearch is slow in starting up, Kibana may
error out trying to reach it, and won't be considered alive. You can
check whether the relevant service has any endpoints:

    $ oc describe service logging-kibana
    Name:                   logging-kibana
    [...]
    Endpoints:              <none>

If any Kibana pods are live, endpoints should be listed. If they are
not, check the state of the Kibana pod(s) and deployment.

Second, the named route for accessing the Kibana service may be masked.
This tends to happen if you do a trial deployment in one project and
then try to deploy in a different project without completely removing the first one.
When multiple routes are declared for the same destination, the default router will route to
the first created. You can check if the route in question is defined in multiple places with:

    $ oc get route  --all-namespaces --selector logging-infra=support
    NAMESPACE   NAME         HOST/PORT                 PATH      SERVICE
    logging     kibana       kibana.example.com                  logging-kibana
    logging     kibana-ops   kibana-ops.example.com              logging-kibana-ops

(In this example there are no overlapping routes.)
