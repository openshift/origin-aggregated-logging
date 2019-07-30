package main

import (
	"encoding/json"
	"fmt"
)

type omelasticsearch struct {
	Name                  string `json:"name"`
	Submitted             int64  `json:"submitted"`
	FailedHTTP            int64  `json:"failed.http"`
	FailedHTTPRequests    int64  `json:"failed.httprequests"`
	FailedCheckConn       int64  `json:"failed.checkConn"`
	FailedEs              int64  `json:"failed.es"`
	ResponseSuccess       int64  `json:"response.success"`
	ResponseBad           int64  `json:"response.bad"`
	ResponseDuplicate     int64  `json:"response.duplicate"`
	ResponseBadArgument   int64  `json:"response.badargument"`
	ResponseBulkRejection int64  `json:"response.bulkrejection"`
	ResponseOther         int64  `json:"response.other"`
	Rebinds               int64  `json:"rebinds"`
}

func newOmelasticsearchFromJSON(b []byte) (*omelasticsearch, error) {
	var pstat omelasticsearch
	err := json.Unmarshal(b, &pstat)
	if err != nil {
		return nil, fmt.Errorf("error decoding omelasticsearch stat `%v`: %v", string(b), err)
	}
	return &pstat, nil
}

func (i *omelasticsearch) toPoints() []*point {
	points := make([]*point, 12)

	points[0] = &point{
		Name:        "omelasticsearch_submitted",
		Type:        counter,
		Value:       i.Submitted,
		Description: "number of messages submitted for output",
		LabelName:   "omelasticsearch",
		LabelValue:  i.Name,
	}

	points[1] = &point{
		Name:        "omelasticsearch_failedhttp",
		Type:        counter,
		Value:       i.FailedHTTP,
		Description: "number of messages rejected due to error returned from HTTP",
		LabelName:   "omelasticsearch",
		LabelValue:  i.Name,
	}

	points[2] = &point{
		Name:        "omelasticsearch_failedhttprequests",
		Type:        counter,
		Value:       i.FailedHTTPRequests,
		Description: "number of requests rejected due to error returned from the HTTP request",
		LabelName:   "omelasticsearch",
		LabelValue:  i.Name,
	}

	points[3] = &point{
		Name:        "omelasticsearch_failedcheckconn",
		Type:        counter,
		Value:       i.FailedCheckConn,
		Description: "number of times we failed to get a connection to Elasticsearch",
		LabelName:   "omelasticsearch",
		LabelValue:  i.Name,
	}

	points[4] = &point{
		Name:        "omelasticsearch_failedes",
		Type:        counter,
		Value:       i.FailedEs,
		Description: "number of times Elasticsearch response contained an error - detailed in responses",
		LabelName:   "omelasticsearch",
		LabelValue:  i.Name,
	}

	points[5] = &point{
		Name:        "omelasticsearch_responsesuccess",
		Type:        counter,
		Value:       i.ResponseSuccess,
		Description: "number of times Elasticsearch response was successful (HTTP 200)",
		LabelName:   "omelasticsearch",
		LabelValue:  i.Name,
	}

	points[6] = &point{
		Name:        "omelasticsearch_responsebad",
		Type:        counter,
		Value:       i.ResponseBad,
		Description: "number of times the Elasticsearch reponse could not be parsed, or was malformed",
		LabelName:   "omelasticsearch",
		LabelValue:  i.Name,
	}

	points[7] = &point{
		Name:        "omelasticsearch_responseduplicate",
		Type:        counter,
		Value:       i.ResponseDuplicate,
		Description: "number of duplicate records created e.g. by bulk index retry (HTTP 409)",
		LabelName:   "omelasticsearch",
		LabelValue:  i.Name,
	}

	points[8] = &point{
		Name:        "omelasticsearch_responsebadargument",
		Type:        counter,
		Value:       i.ResponseBadArgument,
		Description: "number of records rejected due to syntax errors, formatting, unknown arguments (e.g. HTTP 400)",
		LabelName:   "omelasticsearch",
		LabelValue:  i.Name,
	}

	points[9] = &point{
		Name:        "omelasticsearch_responsebulkrejection",
		Type:        counter,
		Value:       i.ResponseBulkRejection,
		Description: "number of records rejected due to Bulk Index Rejection (HTTP 429)",
		LabelName:   "omelasticsearch",
		LabelValue:  i.Name,
	}

	points[10] = &point{
		Name:        "omelasticsearch_responseother",
		Type:        counter,
		Value:       i.ResponseOther,
		Description: "number of records rejected due to unknown reasons",
		LabelName:   "omelasticsearch",
		LabelValue:  i.Name,
	}

	points[11] = &point{
		Name:        "omelasticsearch_rebinds",
		Type:        counter,
		Value:       i.Rebinds,
		Description: "number of times rsyslog reconnected to Elasticsearch",
		LabelName:   "omelasticsearch",
		LabelValue:  i.Name,
	}

	return points
}
