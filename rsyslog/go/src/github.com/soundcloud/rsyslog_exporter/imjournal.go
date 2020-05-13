package main

import (
	"encoding/json"
	"fmt"
)

type imjournal struct {
	Name      string `json:"name"`
	Submitted int64  `json:"submitted"`
	Read      int64  `json:"read"`
	Discarded int64  `json:"discarded"`
	Failed    int64  `json:"failed"`
	//PollFailed                   int64  `json:"poll_failed"`
	Rotations        int64 `json:"rotations"`
	RecoveryAttempts int64 `json:"recovery_attempts"`
	//RatelimitDiscardedInInterval int64  `json:"ratelimit_discarded_in_interval"`
	DiskUsageBytes int64 `json:"disk_usage_bytes"`
}

func newImjournalFromJSON(b []byte) (*imjournal, error) {
	var pstat imjournal
	err := json.Unmarshal(b, &pstat)
	if err != nil {
		return nil, fmt.Errorf("error decoding imjournal stat `%v`: %v", string(b), err)
	}
	return &pstat, nil
}

func (i *imjournal) toPoints() []*point {
	/* should be 9 - PollFailed and RatelimitDiscardedInInterval are unused */
	points := make([]*point, 7)
	ii := 0

	points[ii] = &point{
		Name:        "imjournal_submitted",
		Type:        counter,
		Value:       i.Submitted,
		Description: "messages submitted",
		LabelName:   "imjournal",
		LabelValue:  i.Name,
	}
	ii = ii + 1

	points[ii] = &point{
		Name:        "imjournal_read",
		Type:        counter,
		Value:       i.Read,
		Description: "messages read from journal",
		LabelName:   "imjournal",
		LabelValue:  i.Name,
	}
	ii = ii + 1

	points[ii] = &point{
		Name:        "imjournal_discarded",
		Type:        counter,
		Value:       i.Discarded,
		Description: "messages that were read but discarded",
		LabelName:   "imjournal",
		LabelValue:  i.Name,
	}
	ii = ii + 1

	points[ii] = &point{
		Name:        "imjournal_failed",
		Type:        counter,
		Value:       i.Failed,
		Description: "messages that could not be read due to failure",
		LabelName:   "imjournal",
		LabelValue:  i.Name,
	}
	ii = ii + 1

	/* currently unused
	points[ii] = &point{
		Name:        "imjournal_poll_failed",
		Type:        counter,
		Value:       i.PollFailed,
		Description: "number of times got a failure polling journal",
		LabelName:   "imjournal",
		LabelValue:  i.Name,
	}
	ii = ii + 1
	*/

	points[ii] = &point{
		Name:        "imjournal_rotations",
		Type:        counter,
		Value:       i.Rotations,
		Description: "number of journal rotations detected",
		LabelName:   "imjournal",
		LabelValue:  i.Name,
	}
	ii = ii + 1

	points[ii] = &point{
		Name:        "imjournal_recovery_attempts",
		Type:        counter,
		Value:       i.RecoveryAttempts,
		Description: "number of recovery attempts",
		LabelName:   "imjournal",
		LabelValue:  i.Name,
	}
	ii = ii + 1

	/* currently unused
	points[ii] = &point{
		Name:        "imjournal_ratelimit_discarded_in_interval",
		Type:        counter,
		Value:       i.RatelimitDiscardedInInterval,
		Description: "number of ratelimit discards during poll interval",
		LabelName:   "imjournal",
		LabelValue:  i.Name,
	}
	ii = ii + 1
	*/

	points[ii] = &point{
		Name:        "imjournal_disk_usage_bytes",
		Type:        gauge,
		Value:       i.DiskUsageBytes,
		Description: "disk usage of journal in bytes",
		LabelName:   "imjournal",
		LabelValue:  i.Name,
	}
	ii = ii + 1

	return points
}
