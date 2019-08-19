package main

import (
	"encoding/json"
	"fmt"
)

type dynStat struct {
	Name   string           `json:"name"`
	Origin string           `json:"origin"`
	Values map[string]int64 `json:"values"`
}

func newDynStatFromJSON(b []byte) (*dynStat, error) {
	var pstat dynStat
	err := json.Unmarshal(b, &pstat)
	if err != nil {
		return nil, fmt.Errorf("error decoding values stat `%v`: %v", string(b), err)
	}
	return &pstat, nil
}

func (i *dynStat) toPoints() []*point {
	points := make([]*point, 0, len(i.Values))

	for name, value := range i.Values {
		points = append(points, &point{
			Name:        fmt.Sprintf("dynstat_%s", i.Name),
			Type:        counter,
			Value:       value,
			Description: fmt.Sprintf("dynamic statistic bucket %s", i.Name),
			LabelName:   "counter",
			LabelValue:  name,
		})
	}

	return points
}
