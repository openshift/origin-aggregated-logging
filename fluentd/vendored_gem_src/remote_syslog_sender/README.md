# Remote Syslog Sender

This gem is syslog sender that is extracted from (papertrail/remote_syslog_logger)[https://github.com/papertrail/remote_syslog_logger]

This can send message to remote syslog server via UDP, TCP, TCP+TLS.
(Original does not support TCP, TCP+TLS protocol).

## Installation

The easiest way to install `remote_syslog_sender` is with Bundler. Add
`remote_syslog_sender` to your `Gemfile`.

If you are not using a `Gemfile`, run:

    $ [sudo] gem install remote_syslog_sender


## Usage

```ruby
sender = RemoteSyslogSender.new('syslog.domain.com', 514) # default protocol is UDP
sender.transmit("message body")
# or 
sender.write("message body")


## TCP
sender = RemoteSyslogSender.new('syslog.domain.com', 514, protocol: :tcp)
sender.transmit("message body")

## TCP+TLS
sender = RemoteSyslogSender.new('syslog.domain.com', 514, protocol: :tcp, tls: true, ca_file: "custom_ca.pem")
sender.transmit("message body")
```

To point the logs to your local system, use `localhost` and ensure that
the system's syslog daemon is bound to `127.0.0.1`.


## Limitations

If the specified host cannot be resolved, `syslog.domain.com` in the
example under the usage section above, `remote_syslog_sender` will block
for approximately 20 seconds before displaying an error.  This could
result in the application failing to start or even stopping responding.

Workarounds for this include:

* use an IP address instead of a hostname.
* put a hosts entry in `/etc/hosts` or equivalent, so that DNS is not
actually consulted
* instead of logging directly to the network, write to a file and
transmit new entries with a standalone daemon like
[remote_syslog](https://github.com/papertrail/remote_syslog),

## Message length

All log lines are truncated to a maximum of 1024 characters. This restriction
comes from [RFC 3164 section 4.1][rfc-limit]:

> The total length of the packet MUST be 1024 bytes or less.

Additionally, the generally-accepted [MTU][] of the Internet is 1500 bytes, so
regardless of the RFC, UDP syslog packets longer than 1500 bytes would not
arrive. For details or to use TCP syslog for longer messages, see
[help.papertrailapp.com][troubleshoot].

[rfc-limit]: https://tools.ietf.org/html/rfc3164#section-4.1
[MTU]: (https://en.wikipedia.org/wiki/Maximum_transmission_unit)
[troubleshoot]: http://help.papertrailapp.com/kb/configuration/troubleshooting-remote-syslog-reachability/#message-length


## Default program name

By default, the `program` value is set to the name and ID of the invoking
process. For example, `puma[12345]` or `rack[3456]`.

The `program` value is used to populate the syslog "tag" field, must be 32
or fewer characters. In a few cases, an artifact of how the app is launched
may lead to a default `program` value longer than 32 characters. For example,
the `thin` Web server may generate a default `program` value such
as:

    thin server (0.0.0.0:3001)[11179]

If this occurs, the following exception will be raised when a
`RemoteSyslogSender` is instantiated:

    Tag must not be longer than 32 characters (ArgumentError)

To remedy this, explicitly provide a `program` argument which is shorter than
32 characters. See [Usage](#usage).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/reproio/remote_syslog_sender.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
