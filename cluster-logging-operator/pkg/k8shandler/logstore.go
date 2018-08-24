package k8shandler

import (
  "fmt"
  "github.com/openshift/origin-aggregated-logging/cluster-logging-operator/pkg/apis/logging/v1alpha1"
  "github.com/ViaQ/elasticsearch-operator/pkg/apis/elasticsearch/v1alpha1"
)

func CreateOrUpdateLogStore(logging *v1alpha1.ClusterLogging)(string, error) {

}

func CreateOrUpdateSecret(logging *v1alpha1.ClusterLogging)(string, error) {

}

func CreateOrUpdateCR(logging *v1alpha1.ClusterLogging)(string, error) {

  var esNodes []v1alpha1.ElasticsearchNode

  esNode := v1alpha1.ElasticsearchNode{
    Roles: []v1alpha1.ElasticsearchNodeRole{"client", "data", "master"},
    Replicas: logging.LogStore.Replicas,
    NodeSelector: logging.LogStore.NodeSelector,
    Spec: v1alpha1.ElasticsearchNodeSpec{
      Resources: logging.LogStore.Resources,
    },
    Storage: v1alpha1.ElasticsearchNodeStorageSource{
      VolumeClaimTemplate: //TODO: fill out,
    },
  }

  // build Nodes
  esNodes = append(esNodes, esNode)

  esCR := &v1alpha1.Elasticsearch{
    ObjectMeta: metav1.ObjectMeta{
      Name: "logging-es",
      Namespace: namespace,
    },
    TypeMeta: metav1.TypeMeta{
      Kind: "Elasticsearch",
      APIVersion: "elasticsearch.redhat.com/v1alpha1",
    },
    Spec: v1alpha1.ElasticsearchSpec{
      Nodes: esNodes,
      Secure: v1alpha1.ElasticsearchSecure{
        Disabled: false,
        CertificatesSecret: "logging-elasticsearch",
      },
      ServiceAccountName: "aggregated-logging-elasticsearch",
      ConfigMapName: "logging-elasticsearch",
    },
  }

  logrus.Infof("Created Elasticsearch struct: %v", esCR)

  err = sdk.Create(esCR)
  if err != nil && !errors.IsAlreadyExists(err) {
    logrus.Fatalf("Failure constructing Elasticsearch CR: %v", err)
  } else if errors.IsAlreadyExists(err) {
    // Get existing configMap to check if it is same as what we want
    existingCR := &v1alpha1.Elasticsearch{
      ObjectMeta: metav1.ObjectMeta{
        Name: "logging-es",
        Namespace: namespace,
      },
      TypeMeta: metav1.TypeMeta{
        Kind: "Elasticsearch",
        APIVersion: "elasticsearch.redhat.com/v1alpha1",
      },
    }

    err = sdk.Get(existingCR)
    if err != nil {
      logrus.Fatalf("Unable to get Elasticsearch CR: %v", err)
    }

    logrus.Infof("Found existing CR: %v", existingCR)

    // TODO: Compare existing CR labels, selectors and port
  }

}
