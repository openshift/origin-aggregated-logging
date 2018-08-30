package stub

import (
	"context"

	"github.com/openshift/origin-aggregated-logging/cluster-logging-operator/pkg/apis/logging/v1alpha1"
	"github.com/openshift/origin-aggregated-logging/cluster-logging-operator/pkg/k8shandler"

	"github.com/operator-framework/operator-sdk/pkg/sdk"
	"github.com/sirupsen/logrus"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime/schema"

)

func NewHandler() sdk.Handler {
	return &Handler{}
}

type Handler struct {
	// Fill me
}

func (h *Handler) Handle(ctx context.Context, event sdk.Event) error {
	switch o := event.Object.(type) {
	case *v1alpha1.ClusterLogging:
		return Reconcile(o)
	}
	return nil
}

func Reconcile(logging *v1alpha1.ClusterLogging)(err error) {
	logrus.Info("Started reconciliation")

	// Reconcile certs
  err = k8shandler.CreateOrUpdateCertificates(logging)
	if err != nil {
		logrus.FatalF("Unable to create or update certificates: %v", err)
	}

	// Reconcile Log Store

	// Reconcile Visualization

	// Reconcile Curation

	// Reconcile Collection

	return nil
}
