package main

import "testing"

var (
	omelasticsearchLog = []byte(`{
		"name": "test_omelasticsearch", "origin": "omelasticsearch", "submitted": 772, "failed.http": 10,
		"failed.httprequests": 11, "failed.checkConn": 12, "failed.es": 13, "response.success": 700,
		"response.bad": 1, "response.duplicate": 2, "response.badargument": 3, "response.bulkrejection": 4,
		"response.other": 5, "rebinds": 6 }`)
)

func TestGetOmelasticsearch(t *testing.T) {
	logType := getStatType(omelasticsearchLog)
	if logType != rsyslogOmelasticsearch {
		t.Errorf("detected pstat type should be %d but is %d", rsyslogOmelasticsearch, logType)
	}

	pstat, err := newOmelasticsearchFromJSON([]byte(omelasticsearchLog))
	if err != nil {
		t.Fatalf("expected parsing omelasticsearch stat not to fail, got: %v", err)
	}

	if want, got := "test_omelasticsearch", pstat.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(772), pstat.Submitted; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(10), pstat.FailedHTTP; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(11), pstat.FailedHTTPRequests; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(12), pstat.FailedCheckConn; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(12), pstat.FailedCheckConn; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(13), pstat.FailedEs; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(700), pstat.ResponseSuccess; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(1), pstat.ResponseBad; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(3), pstat.ResponseBadArgument; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(2), pstat.ResponseDuplicate; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(4), pstat.ResponseBulkRejection; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(5), pstat.ResponseOther; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := int64(6), pstat.Rebinds; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}
}

func TestOmelasticsearchtoPoints(t *testing.T) {
	pstat, err := newOmelasticsearchFromJSON([]byte(omelasticsearchLog))
	if err != nil {
		t.Fatalf("expected parsing omelasticsearch stat not to fail, got: %v", err)
	}

	points := pstat.toPoints()

	point := points[0]
	if want, got := "omelasticsearch_submitted", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(772), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_omelasticsearch", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[1]
	if want, got := "omelasticsearch_failedhttp", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(10), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_omelasticsearch", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[2]
	if want, got := "omelasticsearch_failedhttprequests", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(11), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_omelasticsearch", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[3]
	if want, got := "omelasticsearch_failedcheckconn", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(12), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_omelasticsearch", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[4]
	if want, got := "omelasticsearch_failedes", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(13), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_omelasticsearch", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[5]
	if want, got := "omelasticsearch_responsesuccess", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(700), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_omelasticsearch", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[6]
	if want, got := "omelasticsearch_responsebad", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(1), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_omelasticsearch", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[7]
	if want, got := "omelasticsearch_responseduplicate", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(2), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_omelasticsearch", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[8]
	if want, got := "omelasticsearch_responsebadargument", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(3), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_omelasticsearch", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[9]
	if want, got := "omelasticsearch_responsebulkrejection", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(4), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_omelasticsearch", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[10]
	if want, got := "omelasticsearch_responseother", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(5), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_omelasticsearch", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}

	point = points[11]
	if want, got := "omelasticsearch_rebinds", point.Name; want != got {
		t.Errorf("want '%s', got '%s'", want, got)
	}

	if want, got := int64(6), point.Value; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := counter, point.Type; want != got {
		t.Errorf("want '%d', got '%d'", want, got)
	}

	if want, got := "test_omelasticsearch", point.LabelValue; want != got {
		t.Errorf("wanted '%s', got '%s'", want, got)
	}
}
