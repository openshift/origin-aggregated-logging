package k8shandler

import (
  "fmt"
  "encoding/base64"
  "github.com/openshift/origin-aggregated-logging/cluster-logging-operator/pkg/apis/logging/v1alpha1"
  "github.com/sirupsen/logrus"
  "k8s.io/api/core/v1"
  "os"
  "os/exec"
  "io/ioutil"

  sdk "github.com/operator-framework/operator-sdk/pkg/sdk"
  k8sutil "github.com/operator-framework/operator-sdk/pkg/util/k8sutil"
  metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func extractMasterCertificate(namespace string)(string, error) {

  secret := &v1.Secret{TypeMeta: metav1.TypeMeta{Kind: "Secret", APIVersion: "v1"}}
  err = sdk.Query(namespace, secret)

  // value []byte
  value, ok := secret.Data["masterca"]

  // check to see if the map value exists
  if ! ok {
    logrus.FatalF("No secret data found")
    return
  }

  // b64 decode value and use it for creating/signing new certs
  decoded, err := base64.StdEncoding.DecodeString(value)
  err := ioutil.WriteFile("/tmp/_working_dir/ca.crt", decoded, 0644)
  if err != nil {
    logorus.FatalF("Unable to write CA to working dir: %v", err)
  }

  return nil
}

func CreateOrUpdateCertificates(logging *v1alpha1.ClusterLogging)(string, error) {

  // Pull master signing cert out from secret in logging.Spec.SecretName
  namespace, err := k8sutil.GetWatchNamespace()
  if err != nil {
    logrus.FatalF("Failed to get watch namespace: %v", err)
  }

  _,err := extractMasterCertificate(namespace)

  cmd := exec.Command("scripts/cert_generation.sh")
  cmd.Env = append(os.Environ(),
            "NAMESPACE="+namespace,
            )
  if err := cmd.Run(); err != nil {
    logrus.FatalF("Error running script: %v", err)
  }
}
