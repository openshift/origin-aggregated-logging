# Filing An Issue
The Openshift Aggregated Logging integration is a multicomponent technology stack whose individual
parts must all work together to gather and archive logs.  It is important to include as much information
as possible when issues arise in order to properly debug and diagnose.  Run
[logging gathering script](../hack/logging-dump.sh) which will gather the desired information.  Alternatively, you can gather
them manually.

**NOTE:** It is your responsiblity as the reporter of an issue to redact any sensitive information from
any and all artifacts that are included as part of the issue.

Please include as much of the following to help us expedite a resolution:

### OpenShift Cluster Details
1. Cluster version (e.g. OCP v3.5)
2. Cluster infrastructure (e.g. AWS, GCP)
3. Number of infrastructure nodes and size (e.g. CPU, RAM)
4. Number of compute nodes and size (e.g. CPU, RAM)
5. Logging Image versions

**ADD NOTE HERE ON HOW TO RETRIEVE IMAGE VERSION FROM OCP AND ORIGIN**

### Installer Details
1. How was logging installed (e.g. Openshift Ansible/Installer, deployer)
2. Openshift installer version
3. Ansible inventory file
4. Ansible installer logs

### Logging Component Details
1. Elasticsearch logs: `oc logs -l component=es $PODNAME`
2. Other component logs: `oc logs $PODNAME`
3. Fluentd spec: `oc get ds logging-fluentd -o yaml`
4. Other component specs: `oc get dc $DCNAME -o yaml`
5. Configmaps: `oc get configmaps $CONFIGMAP -o yaml`
6. Events: `oc get events $PODNAME -o yaml`
7. Output of https://github.com/openshift/openshift-tools/blob/prod/scripts/monitoring/cron-send-logging-checks.py
