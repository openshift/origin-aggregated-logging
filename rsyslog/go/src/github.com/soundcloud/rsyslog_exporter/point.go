package main

import (
	"errors"
	"fmt"

	"github.com/prometheus/client_golang/prometheus"
)

type pointType int

const (
	counter pointType = iota
	gauge
)

var (
	ErrIncompatiblePointType = errors.New("incompatible point type")
	ErrUnknownPointType      = errors.New("unknown point type")
)

type point struct {
	Name        string
	Description string
	Type        pointType
	Value       int64
	LabelName   string
	LabelValue  string
}

func (p *point) promDescription() *prometheus.Desc {
	return prometheus.NewDesc(
		prometheus.BuildFQName("", "rsyslog", p.Name),
		p.Description,
		[]string{p.promLabelName()},
		nil,
	)
}

func (p *point) promType() prometheus.ValueType {
	if p.Type == counter {
		return prometheus.CounterValue
	}
	return prometheus.GaugeValue
}

func (p *point) promValue() float64 {
	return float64(p.Value)
}

func (p *point) promLabelValue() string {
	return p.LabelValue
}

func (p *point) promLabelName() string {
	return p.LabelName
}

func (p *point) key() string {
	return fmt.Sprintf("%s.%s", p.Name, p.LabelValue)
}
