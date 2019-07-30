package main

import "testing"

var (
	imjournalLog = []byte(`{ "name": "test_imjournal", "origin": "imjournal", "submitted": 1994, "read": 1996, "discarded": 1, "failed": 1, "poll_failed": 0, "rotations": 32, "recovery_attempts": 5, "ratelimit_discarded_in_interval": 0, "disk_usage_bytes": 75501568 }`)
)

func TestGetImjournal(t *testing.T) {
	logType := getStatType(imjournalLog)
	if logType != rsyslogImjournal {
		t.Errorf("detected pstat type should be %d but is %d", rsyslogImjournal, logType)
	}

	pstat, err := newImjournalFromJSON([]byte(imjournalLog))
	if err != nil {
		t.Fatalf("expected parsing imjournal stat not to fail, got: %v", err)
	}

	if want, got := "test_imjournal", pstat.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(1994), pstat.Submitted; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(1996), pstat.Read; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(1), pstat.Discarded; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(1), pstat.Failed; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	/* not yet supported
	if want, got := int64(0), pstat.PollFailed; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}
	*/

	if want, got := int64(32), pstat.Rotations; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(5), pstat.RecoveryAttempts; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	/* not yet supported
	if want, got := int64(0), pstat.RatelimitDiscardedInInterval; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}
	*/

	if want, got := int64(75501568), pstat.DiskUsageBytes; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}
}

func TestImjournaltoPoints(t *testing.T) {
	pstat, err := newImjournalFromJSON([]byte(imjournalLog))
	if err != nil {
		t.Fatalf("expected parsing imjournal stat not to fail, got: %v", err)
	}

	points := pstat.toPoints()

	ii := 0
	point := points[ii]
	if want, got := "imjournal_submitted", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(1994), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_imjournal", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}
	ii = ii + 1

	point = points[ii]
	if want, got := "imjournal_read", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(1996), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_imjournal", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}
	ii = ii + 1

	point = points[ii]
	if want, got := "imjournal_discarded", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(1), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_imjournal", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}
	ii = ii + 1

	point = points[ii]
	if want, got := "imjournal_failed", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(1), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_imjournal", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}
	ii = ii + 1

	/* not yet supported
	point = points[ii]
	if want, got := "imjournal_poll_failed", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(0), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_imjournal", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}
	ii = ii + 1
	*/

	point = points[ii]
	if want, got := "imjournal_rotations", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(32), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_imjournal", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}
	ii = ii + 1

	point = points[ii]
	if want, got := "imjournal_recovery_attempts", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(5), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_imjournal", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}
	ii = ii + 1

	/* not yet supported
	point = points[ii]
	if want, got := "imjournal_ratelimit_discarded_in_interval", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(0), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_imjournal", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}
	ii = ii + 1
	*/

	point = points[ii]
	if want, got := "imjournal_disk_usage_bytes", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(75501568), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := gauge, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_imjournal", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}
	ii = ii + 1
}
