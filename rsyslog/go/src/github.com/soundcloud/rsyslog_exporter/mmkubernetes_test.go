package main

import "testing"

var (
	mmkubernetesLog = []byte(`{
		"name": "test_mmkubernetes",
		"origin": "mmkubernetes", "recordseen": 9876, "namespacemetadatasuccess": 11, "namespacemetadatanotfound": 1,
		"namespacemetadatabusy": 2, "namespacemetadataerror": 3, "podmetadatasuccess": 12, "podmetadatanotfound": 4,
		"podmetadatabusy": 5, "podmetadataerror": 6, "namespacecachenumentries": 13, "podcachenumentries": 14,
		"namespacecachehits": 15, "podcachehits": 16, "namespacecachemisses": 17, "podcachemisses": 18 }`)
)

func TestGetMmkubernetes(t *testing.T) {
	logType := getStatType(mmkubernetesLog)
	if logType != rsyslogMmkubernetes {
		t.Errorf("detected pstat type should be %d but is %d", rsyslogMmkubernetes, logType)
	}

	pstat, err := newMmkubernetesFromJSON([]byte(mmkubernetesLog))
	if err != nil {
		t.Fatalf("expected parsing omelasticsearch stat not to fail, got: %v", err)
	}

	if want, got := "test_mmkubernetes", pstat.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(9876), pstat.RecordSeen; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(11), pstat.NamespaceMetadataSuccess; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(1), pstat.NamespaceMetadataNotfound; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(2), pstat.NamespaceMetadataBusy; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(3), pstat.NamespaceMetadataError; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(12), pstat.PodMetadataSuccess; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(4), pstat.PodMetadataNotfound; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(5), pstat.PodMetadataBusy; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(6), pstat.PodMetadataError; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(13), pstat.NamespaceCacheNumentries; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(14), pstat.PodCacheNumentries; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(15), pstat.NamespaceCacheHits; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(16), pstat.PodCacheHits; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(17), pstat.NamespaceCacheMisses; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(18), pstat.PodCacheMisses; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}
}

func TestMmkubernetestoPoints(t *testing.T) {
	pstat, err := newMmkubernetesFromJSON([]byte(mmkubernetesLog))
	if err != nil {
		t.Fatalf("expected parsing mmkubernetes stat not to fail, got: %v", err)
	}

	points := pstat.toPoints()

	point := points[0]
	if want, got := "mmkubernetes_recordseen", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(9876), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_mmkubernetes", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[1]
	if want, got := "mmkubernetes_namespacemetadatasuccess", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(11), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_mmkubernetes", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[2]
	if want, got := "mmkubernetes_namespacemetadatanotfound", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(1), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_mmkubernetes", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[3]
	if want, got := "mmkubernetes_namespacemetadatabusy", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(2), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_mmkubernetes", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[4]
	if want, got := "mmkubernetes_namespacemetadataerror", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(3), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_mmkubernetes", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[5]
	if want, got := "mmkubernetes_podmetadatasuccess", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(12), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_mmkubernetes", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[6]
	if want, got := "mmkubernetes_podmetadatanotfound", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(4), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_mmkubernetes", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[7]
	if want, got := "mmkubernetes_podmetadatabusy", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(5), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_mmkubernetes", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[8]
	if want, got := "mmkubernetes_podmetadataerror", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(6), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_mmkubernetes", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[9]
	if want, got := "mmkubernetes_namespacecachenumentries", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(13), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := gauge, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_mmkubernetes", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[10]
	if want, got := "mmkubernetes_podcachenumentries", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(14), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := gauge, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_mmkubernetes", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[11]
	if want, got := "mmkubernetes_namespacecachehits", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(15), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_mmkubernetes", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[12]
	if want, got := "mmkubernetes_podcachehits", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(16), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_mmkubernetes", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[13]
	if want, got := "mmkubernetes_namespacecachemisses", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(17), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_mmkubernetes", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[14]
	if want, got := "mmkubernetes_podcachemisses", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(18), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_mmkubernetes", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

}
