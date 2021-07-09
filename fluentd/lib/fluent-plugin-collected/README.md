# fluent-plugin-collected, a plugin for publishing collected_bytes_total metric via prometheus


## Requirements

| fluent-plugin-collected | fluentd    | ruby   |
|--------------------------|------------|--------|
| 1.x.y                    | >= v0.14.8 | >= 2.1 |
| 0.x.y                    | >= v0.12.0 | >= 1.9 |

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fluent-plugin-collected'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-collected

## Usage

fluentd-plugin-collected includes 1 new plugin.

- `collected_tail_monitor` input plugin

See [sample configuration]
  @type collected_tail_monitor
  <metric>
    name log_collected_bytes_total
    type counter
    desc Total bytes collected from file
    <labels>
      tag ${tag}
      hostname ${hostname}
    </labels>
  </metric>

### collected_tail_monitor plugin as input plugin

You have to configure this plugin to expose metrics collected by other Prometheus plugins.
This plugin provides a metrics HTTP endpoint to be scraped by a Prometheus server on 24231/tcp(default).
With following configuration, you can access http://localhost:24231/metrics on a server where fluentd running.

```
<source>
  @type collected_tail_monitor
  <labels>
    host ${hostname}
  </labels>
</source>
```

More configuration parameters:

- `bind`: binding interface (default: '0.0.0.0')
- `port`: listen port (default: 24231)
- `metrics_path`: metrics HTTP endpoint (default: /metrics)
- `aggregated_metrics_path`: metrics HTTP endpoint (default: /aggregated_metrics)

When using multiple workers, each worker binds to port + `fluent_worker_id`.
To scrape metrics from all workers at once, you can access http://localhost:24231/aggregated_metrics.



#### Exposed metrics

- `log_collected_bytes_total`
    - collected total bytes for a given log file

Default labels:

- `plugin_id`: a value set for a plugin in configuration.
- `type`: plugin name. 
- `path`: file path
- `namespace: namespace`
- `podname`: pod name`
- `containername: container name`


Start fluentd with sample configuration. It listens on 24231.

```
$ bundle exec fluentd -c misc/fluentd_sample.conf -v
```
