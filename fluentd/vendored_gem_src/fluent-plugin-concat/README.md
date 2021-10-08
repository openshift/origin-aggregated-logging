# fluent-plugin-concat

[![Build Status](https://travis-ci.org/fluent-plugins-nursery/fluent-plugin-concat.svg?branch=master)](https://travis-ci.org/fluent-plugins-nursery/fluent-plugin-concat)

Fluentd Filter plugin to concatenate multiline log separated in multiple events.

## Requirements

| fluent-plugin-concat | fluentd    | ruby   |
|----------------------|------------|--------|
| >= 2.0.0             | >= v0.14.0 | >= 2.1 |
| < 2.0.0              | >= v0.12.0 | >= 1.9 |

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fluent-plugin-concat'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-concat

## Configuration

### Example

```
<filter docker.log>
  @type concat
  key loga
  #separator "\n"
  n_lines 10
  #multiline_start_regexp /^Start/
  #multiline_end_regexp /^End/
  #continuous_line_regexp nil
  #stream_identity_key nil
  #flush_interval 60
  #timeout_label nil
  #use_first_timestamp false
  #partial_key nil
  #partial_value nil
  #keep_partial_key false
  #use_partial_metadata false
  #keep_partial_metadata false
  #partial\_metadata\_format docker-fluentd
  #use\_partial\_cri\_logtag false
  #partial\_cri\_logtag\_key nil
  #partial\_cri\_stream\_key stream
</filter>
```

### Parameter

|parameter|description|default|
|---|---|---|
|key|The key for part of multiline log||
|separator|The separator of lines|`"\n"`|
|n\_lines|The number of lines. This is exclusive with `multiline_start_regex`|nil|
|multiline\_start\_regexp|The regexp to match beginning of multiline. This is exclusive with `n_lines`|nil|
|multiline\_end\_regexp|The regexp to match ending of multiline.This is exclusive with `n_lines`|nil|
|continuous\_line\_regexp|The regexp to match continuous lines.This is exclusive with `n_lines`|nil|
|stream\_identity\_key|The key to determine which stream an event belongs to|nil|
|flush\_interval|The number of seconds after which the last received event log will be flushed.If specified 0, wait for next line foreverr|60|
|timeout\_label|The label name to handle events caused by timeout|nil|
|use\_first\_timestamp|Use timestamp of first record when buffer is flushed|`false`|
|partial\_key|The field name that is the reference to concatenate records|nil|
|partial\_value|The value stored in the field specified by partial_key that represent partial log|nil|
|keep\_partial\_key|If true, keep partial_key in concatenated records|`false`|
|use\_partial\_metadata|Use partial metadata to concatenate multiple records|`false`|
|keep\_partial\_metadata|If true, keep partial metadata|`false`|
|partial\_metadata\_format|Input format of the partial metadata (fluentd or journald docker log driver) ( `docker-fluentd`, `docker-journald`, `docker-journald-lowercase`)<br>Configure based on the input plugin, that is used. <br>The docker fluentd and journald log drivers are behaving differently, so the plugin needs to know, what to look for.<br>Use `docker-journald-lowercase`, if you have `fields_lowercase true` in the `journald` source config |`docker-fluentd`|
|use\_partial\_cri\_logtag|bool (optional)|Use cri log tag to concatenate multiple records||
|partial\_cri\_logtag\_key|string (optional)|The key name that is referred to concatenate records on cri log||
|partial\_cri\_stream\_key|string (optional)|The key name that is referred to detect stream name on cri log|`stream`|

## Usage

Every 10 events will be concatenated into one event.

```aconf
<filter docker.log>
  @type concat
  key message
  n_lines 10
</filter>
```

Specify first line of multiline by regular expression.

```aconf
<filter docker.log>
  @type concat
  key message
  multiline_start_regexp /^Start/
</filter>
```

You can handle timeout events and remaining buffers on shutdown this plugin.

```aconf
<label @ERROR>
  <match docker.log>
    @type file
    path /path/to/error.log
  </match>
</label>
```

Handle timeout log lines the same as normal logs.

```aconf
<filter **>
  @type concat
  key message
  multiline_start_regexp /^Start/
  flush_interval 5
  timeout_label @NORMAL
</filter>

<match **>
  @type relabel
  @label @NORMAL
</match>

<label @NORMAL>
  <match **>
    @type stdout
  </match>
</label>
```

Handle single line JSON from Docker containers.

```aconf
<filter **>
  @type concat
  key message
  multiline_end_regexp /\n$/
</filter>
```

Handle Docker logs splitted in several parts (using `partial_message`), and do not add new line between parts.

```aconf
<filter>
  @type concat
  key log
  partial_key partial_message
  partial_value true
  separator ""
</filter>
```

(Docker v19.03+) Handle Docker logs splitted in several parts (using `use_partial_metadata`), and do not add new line between parts.

```aconf
<filter>
  @type concat
  key log
  use_partial_metadata true
  separator ""
</filter>
```

(Docker v20.10+) Handle Docker logs splitted in several parts (using `use_partial_metadata`), and do not add new line between parts.

Docker v20.10 improved partial message handling by adding better metadata in the journald log driver, this works now similarily to the fluentd log driver, but requires one additional setting

```aconf
<filter>
  @type concat
  key log
  use_partial_metadata true
  partial_metadata_format docker-journald
  separator ""
</filter>
```

Handle Docker logs splitted in several parts (using newline detection), and do not add new line between parts (prior to Docker 18.06).

```aconf
<filter **>
  @type concat
  key log
  multiline_end_regexp /\\n$/
  separator ""
</filter>
```

Handle containerd/cri in Kubernetes.

```aconf
<source>
  @type tail
  path /var/log/containers/*.log
  <parse>
    @type regexp
    expression /^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>[^ ]*) (?<message>.*)$/
    time_format %Y-%m-%dT%H:%M:%S.%L%z
  </parse>
  tag k8s
  @label @CONCAT
</source>

<label @CONCAT>
  <filter k8s>
    @type concat
    key message
    use_partial_cri_logtag true
    partial_cri_logtag_key logtag
    partial_cri_stream_key stream
  </filter>
  <match k8s>
    @type relabel
    @label @OUTPUT
  </match>
</label>

<label @OUTPUT>
  <match>
    @type stdout
  </match>
</label>
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

