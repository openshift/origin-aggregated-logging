# fluent-plugin-remote_syslog

[![Build Status](https://travis-ci.org/dlackty/fluent-plugin-remote_syslog.svg?branch=master)](https://travis-ci.org/dlackty/fluent-plugin-remote_syslog)

[Fluentd](http://fluentd.org) plugin for output to remote syslog serivce (e.g. [Papertrail](http://papertrailapp.com/))

## Requirements

| fluent-plugin-remote_syslog | fluentd                 | ruby   |
| -------------------         | ---------               | ------ |
| >= 1.0.0                    | >= v0.14.0 or >= v1.0.0 | >= 2.1 |
| < 1.0.0                     | >= v0.12.0              | >= 1.9 |

## Installation

```bash
 fluent-gem install fluent-plugin-remote_syslog
```

## Usage

```
<match foo.bar>
  @type remote_syslog
  host example.com
  port 514
  severity debug
  program fluentd
  hostname ${tag[1]}

  <buffer tag>
  </buffer>

  <format>
    @type single_value
    message_key msg
  </format>
</match>
```

## Configuration

| name              | type                             | placeholder support | description                                           |
| --------------    | -------                          | -----------         | ---------------------------------                     |
| hostname          | string                           | support             | departure of log                                      |
| host              | string                           | support             | syslog target host                                    |
| port              | integer (default: `514`)         |                     | syslog target port                                    |
| host_with_port    | string                           | support             | parameter for <host>:<port> style                     |
| facility          | string (default: `"user"`)       | support             | syslog facility                                       |
| severity          | string (default: `"notice"`      | support             | syslog severity                                       |
| program           | string (default: `"fluentd"`     | support             | syslog program name                                   |
| protocol          | enum (udp, tcp) (default: `udp`) |                     | transfer protocol                                     |
| tls               | bool (default: false)            |                     | use TLS (tcp only)                                    |
| ca_file           | string                           |                     | ca_file path (tls mode only)                          |
| verify_mode       | integer                          |                     | SSL verification mode (tls mode only)                 |
| packet_size       | integer (default: `1024`)        |                     | size limitation for syslog packet                     |
| timeout           | integer                          |                     | TCP transfer timeout. if value is 0, wait forever     |
| timeout_exception | bool (default: `false`)          |                     | if value is true, raise exception by transfer timeout |
| keep_alive        | bool (default: `false`)          |                     | use TCP keep alive                                    |
| keep_alive_idle   | integer                          |                     | set TCP keep alive idle time                          |
| keep_alive_cnt    | integer                          |                     | set TCP keep alive probe count                        |
| keep_alive_intvl  | integer                          |                     | set TCP keep alive probe interval                     |

### Common Configuration

#### Buffer Section

| name                        | default  |
| --------------              | -------  |
| flush_mode                  | interval |
| flush_interval              | 5        |
| flush_thread_interval       | 0.5      |
| flush_thread_burst_interval | 0.5      |

#### Format Section

| name           | default |
| -------------- | ------- |
| @type          | ltsv    |

## License

Copyright (c) 2014-2017 Richard Lee. See LICENSE for details.
