# ChangeLog

## next

### Improvements

* adds `partial_metadata_format` to support Docker 20.10 journald log driver improvements [moby/moby#41407](https://github.com/moby/moby/pull/41407) 

## v2.3.0

### Improvements

* Support `partial_key`, `partial_value` to concatenate split log lines. See #46, #52

## v2.2.3

### Fixes

* Fix a bug that `@timeout_map` will be updated while traversing it. See #49

## v.2.2.2

### Fixes

* #48

## v2.2.1

### Fixes

* #45

## v2.2.0

### Fixes

* #43

## v2.0.0

* Use Fluentd v0.14 API and drop Fluentd v0.12 or earlier support

## v0.6.2

### Fixes

* Handle timeout event properly when buffer is empty
* Match both `multiline_start_regexp` and `multiline_end_regexp` properly

## v0.6.0

### Improvements

* Wait next line forever when `flush_interval` is 0
* Add `use_first_timestamp`

### Incompatibilities

* Flush buffer when match both `multiline_start_regexp` and `multiline_end_regexp`

