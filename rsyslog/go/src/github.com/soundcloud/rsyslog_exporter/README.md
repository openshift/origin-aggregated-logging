# rsyslog_exporter [![Build Status](https://travis-ci.org/digitalocean/rsyslog_exporter.svg?branch=master)](https://travis-ci.org/digitalocean/rsyslog_exporter)

A [prometheus](http://prometheus.io/) exporter for [rsyslog](http://rsyslog.com). It accepts rsyslog [impstats](http://www.rsyslog.com/doc/master/configuration/modules/impstats.html) metrics in JSON format over stdin via the rsyslog [omprog](http://www.rsyslog.com/doc/v8-stable/configuration/modules/omprog.html) plugin and transforms and exposes them for consumption by Prometheus.

## Rsyslog Configuration
Configure rsyslog to push JSON formatted stats via omprog:
```
module(
  load="impstats"
  interval="10"
  format="json"
  resetCounters="off"
  ruleset="process_stats"
)

ruleset(name="process_stats") {
  action(
    type="omprog"
    name="to_exporter"
    binary="/usr/local/bin/rsyslog_exporter"
  )
}
```

The exporter itself logs back via syslog, this cannot be configured at the moment.

## Provided Metrics
The following metrics provided by the rsyslog impstats module are tracked by rsyslog_exporter:

### Actions
Action objects describe what is to be done with a message, and are implemented via output modules.
For each action object, the following metrics are provided:

* processed - messages processed by this action
* failed - number of messages this action failed to process
* suspended - number of times this action was suspended
* suspended_duration - amount of time this action has spent in a suspended state
* resumed - number of times this action has resumed from a suspended state

### Inputs
Input objects describe message input sources.
For each input object, the following metrics are provided:

* submitted - messages submitted to this input

### Queues
Queues in rsyslog are used for the main message queue and for actions.  Additionally, each ruleset
in an rsyslog configuration may optionally have its own separate main queue.  For each queue,
the following metrics are provided:

* size - messages currently in queue
* enqueued - total messages enqueued during lifetime of queue
* full - number of times the queue was full
* discarded_full - number of times messages were discarded due to the queue being full
* discarded_not_full - number of times messages discarded but queue was not full
* max_queue_size - maximum size the queue reached during its lifetime

### Resources
Rsyslog tracks how it uses system resources and provides the following metrics:

* utime - user time used in microseconds
* stime - system time used in microseconds
* maxrss - maximum resident set size
* minflt - total number of minor faults
* majflt - total number of major faults
* inblock - number of filesystem input operations
* oublock - number of filesystem output operations
* nvcsw - number of voluntary context switches
* nivcsw - number of involuntary context switches


