package main

import (
	"errors"
	"sort"
	"sync"
)

var (
	ErrPointNotFound = errors.New("point does not exist")
)

type pointStore struct {
	pointMap map[string]*point
	lock     *sync.RWMutex
}

func newPointStore() *pointStore {
	return &pointStore{
		pointMap: make(map[string]*point),
		lock:     &sync.RWMutex{},
	}
}

func (ps *pointStore) keys() []string {
	ps.lock.Lock()
	keys := make([]string, 0)
	for k, _ := range ps.pointMap {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	ps.lock.Unlock()
	return keys
}

func (ps *pointStore) set(p *point) error {
	var err error
	ps.lock.Lock()
	ps.pointMap[p.key()] = p
	ps.lock.Unlock()
	return err
}

func (ps *pointStore) get(name string) (*point, error) {
	ps.lock.Lock()
	if p, ok := ps.pointMap[name]; ok {
		ps.lock.Unlock()
		return p, nil
	}
	ps.lock.Unlock()
	return &point{}, ErrPointNotFound
}
