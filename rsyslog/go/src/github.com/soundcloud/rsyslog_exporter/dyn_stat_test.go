package main

import (
	"reflect"
	"testing"
)

func TestGetDynStat(t *testing.T) {
	log := []byte(`{ "name": "global", "origin": "dynstats", "values": { "msg_per_host.ops_overflow": 1, "msg_per_host.new_metric_add": 3, "msg_per_host.no_metric": 0, "msg_per_host.metrics_purged": 0, "msg_per_host.ops_ignored": 0 } }`)
	values := map[string]int64{
		"msg_per_host.ops_overflow":   1,
		"msg_per_host.new_metric_add": 3,
		"msg_per_host.no_metric":      0,
		"msg_per_host.metrics_purged": 0,
		"msg_per_host.ops_ignored":    0,
	}

	if want, got := rsyslogDynStat, getStatType(log); want != got {
		t.Errorf("detected pstat type should be %d but is %d", want, got)
	}

	pstat, err := newDynStatFromJSON(log)
	if err != nil {
		t.Fatalf("expected parsing dynamic stat not to fail, got: %v", err)
	}

	if want, got := "global", pstat.Name; want != got {
		t.Errorf("invalid name, want '%s', got '%s'", want, got)
	}

	if want, got := values, pstat.Values; !reflect.DeepEqual(want, got) {
		t.Errorf("unexpected values, want: %+v got: %+v", want, got)
	}
}

func TestDynStatToPoints(t *testing.T) {
	log := []byte(`{ "name": "global", "origin": "dynstats", "values": { "msg_per_host.ops_overflow": 1, "msg_per_host.new_metric_add": 3, "msg_per_host.no_metric": 0, "msg_per_host.metrics_purged": 0, "msg_per_host.ops_ignored": 0 } }`)
	wants := map[string]point{
		"msg_per_host.ops_overflow": point{
			Name:        "dynstat_global",
			Type:        counter,
			Value:       1,
			Description: "dynamic statistic bucket global",
			LabelName:   "counter",
			LabelValue:  "msg_per_host.ops_overflow",
		},
		"msg_per_host.new_metric_add": point{
			Name:        "dynstat_global",
			Type:        counter,
			Value:       3,
			Description: "dynamic statistic bucket global",
			LabelName:   "counter",
			LabelValue:  "msg_per_host.new_metric_add",
		},
		"msg_per_host.no_metric": point{
			Name:        "dynstat_global",
			Type:        counter,
			Value:       0,
			Description: "dynamic statistic bucket global",
			LabelName:   "counter",
			LabelValue:  "msg_per_host.no_metric",
		},
		"msg_per_host.metrics_purged": point{
			Name:        "dynstat_global",
			Type:        counter,
			Value:       0,
			Description: "dynamic statistic bucket global",
			LabelName:   "counter",
			LabelValue:  "msg_per_host.metrics_purged",
		},
		"msg_per_host.ops_ignored": point{
			Name:        "dynstat_global",
			Type:        counter,
			Value:       0,
			Description: "dynamic statistic bucket global",
			LabelName:   "counter",
			LabelValue:  "msg_per_host.ops_ignored",
		},
	}

	seen := map[string]bool{}
	for name, _ := range wants {
		seen[name] = false
	}

	pstat, err := newDynStatFromJSON(log)
	if err != nil {
		t.Fatalf("expected parsing dyn stat not to fail, got: %v", err)
	}

	points := pstat.toPoints()
	for _, got := range points {
		key := got.LabelValue
		want, ok := wants[key]
		if !ok {
			t.Errorf("unexpected point, got: %+v", got)
			continue
		}

		if !reflect.DeepEqual(want, *got) {
			t.Errorf("expected point to be %+v, got %+v", want, got)
		}

		if seen[key] {
			t.Errorf("point seen multiple times: %+v", got)
		}
		seen[key] = true
	}

	for name, ok := range seen {
		if !ok {
			t.Errorf("expected to see point with key %s, but did not", name)
		}
	}
}
