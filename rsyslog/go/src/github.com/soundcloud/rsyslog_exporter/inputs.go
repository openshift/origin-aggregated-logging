package main

import (
	"encoding/json"
	"fmt"
)

type input struct {
	Name      string `json:"name"`
	Submitted int64  `json:"submitted"`
}

func newInputFromJSON(b []byte) (*input, error) {
	var pstat input
	err := json.Unmarshal(b, &pstat)
	if err != nil {
		return nil, fmt.Errorf("error decoding input stat `%v`: %v", string(b), err)
	}
	return &pstat, nil
}

func (i *input) toPoints() []*point {
	points := make([]*point, 1)

	points[0] = &point{
		Name:        "input_submitted",
		Type:        counter,
		Value:       i.Submitted,
		Description: "messages submitted",
		LabelName:   "input",
		LabelValue:  i.Name,
	}

	return points
}
