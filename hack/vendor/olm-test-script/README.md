# OLM Test Script

## Description
This script can be used to test install your operator's manifest file in an OCP cluster

### Variables
| *DEBUG* | default false | Set this to true to enable debug output of the e2e-olm script |

| *TEST_NAMESPACE* | default olm-test | This is the namespace where the test subscription, operator group, and csv will be installed to. Note: this will not be created by this script. |

| *TARGET_NAMESPACE* | default olm-test | This is the namespace which contains the CR managed by this operator |

| *MANIFEST_DIR* | default ./deploy/manifests | This is the path to your operator's manifest directory. |

| *VERSION* | default 4.1 | The version directory under $MANIFEST_DIR where your operator's csv file exists. |

### Execution
MANIFEST_DIR=/data/src/github.com/openshift/ansible-service-broker ./e2e-olm.sh

`TARGET_NAMESPACE` - for example, cluster logging uses the `elasticsearch-operator` deployed in the
`openshift-operators-redhat` namespace, but the actual `elasticsearch` CR is created in the
`openshift-logging` namespace, as are the actual Elasticsearch pods and other resources managed by
the `elasticsearch-operator`.  Therefore, when using the script to deploy the `elasticsearch-operator`,
use `TARGET_NAMESPACE=openshift-logging` so that the operator can manage resources in the `openshift-logging`
namespace, even though the elasticsearch subscription and operator are in the `openshift-operators-redhat`
namespace.

### Debugging

#### If the test fails while checking the status of subscriptions/olm-testing
Remove any previously created objects for this test (if you are using the olm-test namespace you can simply run 'oc delete namespace olm-test && oc create namespace olm-test').

If that does not resolve this, verify that your \*package.yaml file is pointing to the correct csv in your manifest dir.

#### If the test fails while installing your CSV
Your operator may not have been able to start as part of the installation; check the events of your operator pod and adjust your manifest accordingly.
oc get pods -n olm-test
oc describe pod -n olm-test {pod_name}
