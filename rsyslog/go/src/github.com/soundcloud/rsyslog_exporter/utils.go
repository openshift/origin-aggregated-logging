package main

import (
	"regexp"
	"strings"
)

var (
	imjournalPattern        = regexp.MustCompile(`"origin"\s*:\s*"imjournal"`)
	omelasticesearchPattern = regexp.MustCompile(`"origin"\s*:\s*"omelasticsearch"`)
	mmkubernetesPattern     = regexp.MustCompile(`"origin"\s*:\s*"mmkubernetes"`)
)

func getStatType(buf []byte) rsyslogType {
	line := string(buf)
	if strings.Contains(line, "processed") {
		return rsyslogAction
	} else if strings.Contains(line, "submitted") {
		// see if imjournal
		if imjournalPattern.MatchString(line) {
			return rsyslogImjournal
		} else if omelasticesearchPattern.MatchString(line) {
			return rsyslogOmelasticsearch
		}
		return rsyslogInput
	} else if strings.Contains(line, "enqueued") {
		return rsyslogQueue
	} else if strings.Contains(line, "utime") {
		return rsyslogResource
	} else if strings.Contains(line, "dynstats") {
		return rsyslogDynStat
	} else if mmkubernetesPattern.MatchString(line) {
		return rsyslogMmkubernetes
	}

	return rsyslogUnknown
}
