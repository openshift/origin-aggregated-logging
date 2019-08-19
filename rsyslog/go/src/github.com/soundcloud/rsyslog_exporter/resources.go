package main

import (
	"encoding/json"
	"fmt"
)

type resource struct {
	Name     string `json:"name"`
	Utime    int64  `json:"utime"`
	Stime    int64  `json:"stime"`
	Maxrss   int64  `json:"maxrss"`
	Minflt   int64  `json:"minflt"`
	Majflt   int64  `json:"majflt"`
	Inblock  int64  `json:"inblock"`
	Outblock int64  `json:"oublock"`
	Nvcsw    int64  `json:"nvcsw"`
	Nivcsw   int64  `json:"nivcsw"`
}

func newResourceFromJSON(b []byte) (*resource, error) {
	var pstat resource
	err := json.Unmarshal(b, &pstat)
	if err != nil {
		return nil, fmt.Errorf("failed to decode resource stat `%v`: %v", string(b), err)
	}
	return &pstat, nil
}

func (r *resource) toPoints() []*point {
	points := make([]*point, 9)

	points[0] = &point{
		Name:        "resource_utime",
		Type:        counter,
		Value:       r.Utime,
		Description: "user time used in microseconds",
		LabelName:   "resource",
		LabelValue:  r.Name,
	}

	points[1] = &point{
		Name:        "resource_stime",
		Type:        counter,
		Value:       r.Stime,
		Description: "system time used in microsends",
		LabelName:   "resource",
		LabelValue:  r.Name,
	}

	points[2] = &point{
		Name:        "resource_maxrss",
		Type:        gauge,
		Value:       r.Maxrss,
		Description: "maximum resident set size",
		LabelName:   "resource",
		LabelValue:  r.Name,
	}

	points[3] = &point{
		Name:        "resource_minflt",
		Type:        counter,
		Value:       r.Minflt,
		Description: "total minor faults",
		LabelName:   "resource",
		LabelValue:  r.Name,
	}

	points[4] = &point{
		Name:        "resource_majflt",
		Type:        counter,
		Value:       r.Majflt,
		Description: "total major faults",
		LabelName:   "resource",
		LabelValue:  r.Name,
	}

	points[5] = &point{
		Name:        "resource_inblock",
		Type:        counter,
		Value:       r.Inblock,
		Description: "filesystem input operations",
		LabelName:   "resource",
		LabelValue:  r.Name,
	}

	points[6] = &point{
		Name:        "resource_oublock",
		Type:        counter,
		Value:       r.Outblock,
		Description: "filesystem output operations",
		LabelName:   "resource",
		LabelValue:  r.Name,
	}

	points[7] = &point{
		Name:        "resource_nvcsw",
		Type:        counter,
		Value:       r.Nvcsw,
		Description: "voluntary context switches",
		LabelName:   "resource",
		LabelValue:  r.Name,
	}

	points[8] = &point{
		Name:        "resource_nivcsw",
		Type:        counter,
		Value:       r.Nivcsw,
		Description: "involuntary context switches",
		LabelName:   "resource",
		LabelValue:  r.Name,
	}

	return points
}
