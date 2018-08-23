package v1alpha1

import (
  metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

type ClusterLoggingList struct {
  metav1.TypeMeta   `json:",inline"`
  metav1.ListMeta   `json:"metadata"`
  Items             []ClusterLogging `json:"items"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

type ClusterLogging struct {
  metav1.TypeMeta   `json:",inline"`
  metav1.ObjectMeta `json:"metadata"`
  Spec              ClusterLoggingSpec   `json:"spec"`
  Status            ClusterLoggingStatus `json:"status,omitempty"`
}

type ClusterLoggingSpec struct {
  AllInOne          bool `json:allinone`
  Visualization     VisualizationSpec `json:"visualization"`
  LogStore          LogStoreSpec `json:"logStore"`
  Collection        CollectionSpec `json:"collection"`
  Curation          CurationSpec `json:"curation"`
}

// This is the struct that will contain information pertinent to Log visualization (Kibana)
type VisualizationSpec struct {
  Disabled          bool `json:"disabled"`
  Resources         v1.ResourceRequirements `json:"resources"`
  NodeSelector      map[string]string `json:"nodeSelector,omitempty"`
  Replicas          int32 `json:"replicas"`
}

// This is the struct that will contain information pertinent to Log storage (Elasticsearch)
type LogStoreSpec struct {
  Disabled          bool `json:"disabled"`
  Resources         v1.ResourceRequirements `json:"resources"`
  NodeSelector      map[string]string `json:"nodeSelector,omitempty"`
}

// This is the struct that will contain information pertinent to Log collection (Fluentd)
type CollectionSpec struct {
  Disabled          bool `json:"disabled"`
  Resources         v1.ResourceRequirements `json:"resources"`
  NodeSelector      map[string]string `json:"nodeSelector,omitempty"`
  Normalizer        NormalizerSpec `json:normalizerSpec, omitempty"`
}

// This is the struct that will contain information pertinent to Log normalization (Mux)
type NormalizerSpec struct {
  Disabled          bool `json:"disabled"`
  Resources         v1.ResourceRequirements `json:"resources"`
  NodeSelector      map[string]string `json:"nodeSelector,omitempty"`
}

// This is the struct that will contain information pertinent to Log curation (Curator)
type CurationSpec struct {
  Disabled          bool `json:"disabled"`
  Resources         v1.ResourceRequirements `json:"resources"`
  NodeSelector      map[string]string `json:"nodeSelector,omitempty"`
  Schedule          string `json:"schedule"`
}

type ClusterLoggingStatus struct {
  Visualization     VisualizationStatus `json:"visualization"`
  LogStore          LogStoreStatus `json:"logStore"`
  Collection        CollectionStatus `json:"collection"`
  Curation          CurationStatus `json:"curation"`
}

type VisualizationStatus struct {
  Disabled          bool `json:disabled`
  Replicas          int32 `json:"replicas"`
  ReplicaSets       []string `json:"replicaSets"`
  Pods              []string `json:"pods"`
}

type LogStoreStatus struct {
  Disabled          bool `json:disabled`
  Replicas          int32 `json:"replicas"`
  ReplicaSets       []string `json:"replicaSets"`
  Pods              []string `json:"pods"`
}

type CollectionStatus struct {
  Disabled          bool `json:disabled`
  DaemonSets         []string `json:"daemonSets"`
  Nodes             []string `json:"nodes"`
  Pods              []string `json:"pods"`
  NormalizerStatus  NormalizerStatus `json:"normalizerStatus"`
}

type NormalizerStatus struct {
  Disabled          bool `json:disabled`
  Replicas          int32 `json:"replicas"`
  ReplicaSets       []string `json:"replicaSets"`
  Pods              []string `json:"pods"`
}

type CurationStatus struct {
  Disabled          bool `json:disabled`
  ChronJobs         []string `json:"chronJobs"`
  Schedules         []string `json:"schedules"`
}
