package main

import (
	"encoding/json"
	"fmt"
)

type action struct {
	Name              string `json:"name"`
	Processed         int64  `json:"processed"`
	Failed            int64  `json:"failed"`
	Suspended         int64  `json:"suspended"`
	SuspendedDuration int64  `json:"suspended.duration"`
	Resumed           int64  `json:"resumed"`
}

func newActionFromJSON(b []byte) (*action, error) {
	var pstat action
	err := json.Unmarshal(b, &pstat)
	if err != nil {
		return nil, fmt.Errorf("failed to decode action stat `%v`: %v", string(b), err)
	}
	return &pstat, nil
}

func (a *action) toPoints() []*point {
	points := make([]*point, 5)

	points[0] = &point{
		Name:        "action_processed",
		Type:        counter,
		Value:       a.Processed,
		Description: "messages processed",
		LabelName:   "action",
		LabelValue:  a.Name,
	}

	points[1] = &point{
		Name:        "action_failed",
		Type:        counter,
		Value:       a.Failed,
		Description: "messages failed",
		LabelName:   "action",
		LabelValue:  a.Name,
	}

	points[2] = &point{
		Name:        "action_suspended",
		Type:        counter,
		Value:       a.Suspended,
		Description: "times suspended",
		LabelName:   "action",
		LabelValue:  a.Name,
	}

	points[3] = &point{
		Name:        "action_suspended_duration",
		Type:        counter,
		Value:       a.SuspendedDuration,
		Description: "time spent suspended",
		LabelName:   "action",
		LabelValue:  a.Name,
	}

	points[4] = &point{
		Name:        "action_resumed",
		Type:        counter,
		Value:       a.Resumed,
		Description: "times resumed",
		LabelName:   "action",
		LabelValue:  a.Name,
	}

	return points
}
