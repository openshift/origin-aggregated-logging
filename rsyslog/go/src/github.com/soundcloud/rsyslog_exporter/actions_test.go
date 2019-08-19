package main

import "testing"

var (
	actionLog = []byte(`{"name":"test_action","processed":100000,"failed":2,"suspended":1,"suspended.duration":1000,"resumed":1}`)
)

func TestNewActionFromJSON(t *testing.T) {
	logType := getStatType(actionLog)
	if logType != rsyslogAction {
		t.Errorf("detected pstat type should be %d but is %d", rsyslogAction, logType)
	}

	pstat, err := newActionFromJSON([]byte(actionLog))
	if err != nil {
		t.Fatalf("expected parsing action not to fail, got: %v", err)
	}

	if want, got := "test_action", pstat.Name; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	if want, got := int64(100000), pstat.Processed; want != got {
		t.Errorf("wanted '%d', got '%d'", want, got)
	}

	if want, got := int64(2), pstat.Failed; want != got {
		t.Errorf("wanted '%d', got '%d'", want, got)
	}

	if want, got := int64(1), pstat.Suspended; want != got {
		t.Errorf("wanted '%d', got '%d'", want, got)
	}

	if want, got := int64(1000), pstat.SuspendedDuration; want != got {
		t.Errorf("wanted '%d', got '%d'", want, got)
	}

	if want, got := int64(1), pstat.Resumed; want != got {
		t.Errorf("wanted '%d', got '%d'", want, got)
	}
}

func TestActionToPoints(t *testing.T) {
	pstat, err := newActionFromJSON([]byte(actionLog))
	if err != nil {
		t.Fatalf("expected parsing action not to fail, got: %v", err)
	}
	points := pstat.toPoints()

	point := points[0]
	if want, got := "action_processed", point.Name; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	if want, got := int64(100000), point.Value; want != got {
		t.Errorf("wanted '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("wanted '%d', got '%d'", want, got)
	}

	if want, got := "test_action", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[1]
	if want, got := "action_failed", point.Name; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	if want, got := int64(2), point.Value; want != got {
		t.Errorf("wanted '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("wanted '%d', got '%d'", want, got)
	}

	if want, got := "test_action", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[2]
	if want, got := "action_suspended", point.Name; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	if want, got := int64(1), point.Value; want != got {
		t.Errorf("wanted '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("wanted '%d', got '%d'", want, got)
	}

	if want, got := "test_action", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[3]
	if want, got := "action_suspended_duration", point.Name; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	if want, got := int64(1000), point.Value; want != got {
		t.Errorf("wanted '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("wanted '%d', got '%d'", want, got)
	}

	if want, got := "test_action", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[4]
	if want, got := "action_resumed", point.Name; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	if want, got := int64(1), point.Value; want != got {
		t.Errorf("wanted '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("wanted '%d', got '%d'", want, got)
	}

	if want, got := "test_action", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}
}
