package main

import (
	"encoding/json"
	"fmt"
)

type mmkubernetes struct {
	Name                      string `json:"name"`
	RecordSeen                int64  `json:"recordseen"`
	NamespaceMetadataSuccess  int64  `json:"namespacemetadatasuccess"`
	NamespaceMetadataNotfound int64  `json:"namespacemetadatanotfound"`
	NamespaceMetadataBusy     int64  `json:"namespacemetadatabusy"`
	NamespaceMetadataError    int64  `json:"namespacemetadataerror"`
	PodMetadataSuccess        int64  `json:"podmetadatasuccess"`
	PodMetadataNotfound       int64  `json:"podmetadatanotfound"`
	PodMetadataBusy           int64  `json:"podmetadatabusy"`
	PodMetadataError          int64  `json:"podmetadataerror"`
	NamespaceCacheNumentries  int64  `json:"namespacecachenumentries"`
	PodCacheNumentries        int64  `json:"podcachenumentries"`
	NamespaceCacheHits        int64  `json:"namespacecachehits"`
	PodCacheHits              int64  `json:"podcachehits"`
	NamespaceCacheMisses      int64  `json:"namespacecachemisses"`
	PodCacheMisses            int64  `json:"podcachemisses"`
}

func newMmkubernetesFromJSON(b []byte) (*mmkubernetes, error) {
	var pstat mmkubernetes
	err := json.Unmarshal(b, &pstat)
	if err != nil {
		return nil, fmt.Errorf("error decoding mmkubernetes stat `%v`: %v", string(b), err)
	}
	return &pstat, nil
}

func (i *mmkubernetes) toPoints() []*point {
	points := make([]*point, 15)

	points[0] = &point{
		Name:        "mmkubernetes_recordseen",
		Type:        counter,
		Value:       i.RecordSeen,
		Description: "number of messages processed from Kubernetes container logs",
		LabelName:   "mmkubernetes",
		LabelValue:  i.Name,
	}

	points[1] = &point{
		Name:        "mmkubernetes_namespacemetadatasuccess",
		Type:        counter,
		Value:       i.NamespaceMetadataSuccess,
		Description: "number of successful queries for namespace metadata",
		LabelName:   "mmkubernetes",
		LabelValue:  i.Name,
	}

	points[2] = &point{
		Name:        "mmkubernetes_namespacemetadatanotfound",
		Type:        counter,
		Value:       i.NamespaceMetadataNotfound,
		Description: "number of unsuccessful queries for namespace metadata due to missing namespace (HTTP 404)",
		LabelName:   "mmkubernetes",
		LabelValue:  i.Name,
	}

	points[3] = &point{
		Name:        "mmkubernetes_namespacemetadatabusy",
		Type:        counter,
		Value:       i.NamespaceMetadataBusy,
		Description: "number of unsuccessful queries for namespace metadata due to busy (HTTP 429) response",
		LabelName:   "mmkubernetes",
		LabelValue:  i.Name,
	}

	points[4] = &point{
		Name:        "mmkubernetes_namespacemetadataerror",
		Type:        counter,
		Value:       i.NamespaceMetadataError,
		Description: "number of unsuccessful queries for namespace metadata due to unknown response",
		LabelName:   "mmkubernetes",
		LabelValue:  i.Name,
	}

	points[5] = &point{
		Name:        "mmkubernetes_podmetadatasuccess",
		Type:        counter,
		Value:       i.PodMetadataSuccess,
		Description: "number of successful queries for pod metadata",
		LabelName:   "mmkubernetes",
		LabelValue:  i.Name,
	}

	points[6] = &point{
		Name:        "mmkubernetes_podmetadatanotfound",
		Type:        counter,
		Value:       i.PodMetadataNotfound,
		Description: "number of unsuccessful queries for pod metadata due to missing pod (HTTP 404)",
		LabelName:   "mmkubernetes",
		LabelValue:  i.Name,
	}

	points[7] = &point{
		Name:        "mmkubernetes_podmetadatabusy",
		Type:        counter,
		Value:       i.PodMetadataBusy,
		Description: "number of unsuccessful queries for pod metadata due to busy (HTTP 429) response",
		LabelName:   "mmkubernetes",
		LabelValue:  i.Name,
	}

	points[8] = &point{
		Name:        "mmkubernetes_podmetadataerror",
		Type:        counter,
		Value:       i.PodMetadataError,
		Description: "number of unsuccessful queries for pod metadata due to unknown response",
		LabelName:   "mmkubernetes",
		LabelValue:  i.Name,
	}

	points[9] = &point{
		Name:        "mmkubernetes_namespacecachenumentries",
		Type:        gauge,
		Value:       i.NamespaceCacheNumentries,
		Description: "number of entries in namespace metadata cache",
		LabelName:   "mmkubernetes",
		LabelValue:  i.Name,
	}

	points[10] = &point{
		Name:        "mmkubernetes_podcachenumentries",
		Type:        gauge,
		Value:       i.PodCacheNumentries,
		Description: "number of entries in pod metadata cache",
		LabelName:   "mmkubernetes",
		LabelValue:  i.Name,
	}

	points[11] = &point{
		Name:        "mmkubernetes_namespacecachehits",
		Type:        counter,
		Value:       i.NamespaceCacheHits,
		Description: "number of namespace metadata cache hits",
		LabelName:   "mmkubernetes",
		LabelValue:  i.Name,
	}

	points[12] = &point{
		Name:        "mmkubernetes_podcachehits",
		Type:        counter,
		Value:       i.PodCacheHits,
		Description: "number of pod metadata cache hits",
		LabelName:   "mmkubernetes",
		LabelValue:  i.Name,
	}

	points[13] = &point{
		Name:        "mmkubernetes_namespacecachemisses",
		Type:        counter,
		Value:       i.NamespaceCacheMisses,
		Description: "number of namespace metadata cache misses",
		LabelName:   "mmkubernetes",
		LabelValue:  i.Name,
	}

	points[14] = &point{
		Name:        "mmkubernetes_podcachemisses",
		Type:        counter,
		Value:       i.PodCacheMisses,
		Description: "number of pod metadata cache misses",
		LabelName:   "mmkubernetes",
		LabelValue:  i.Name,
	}

	return points
}
