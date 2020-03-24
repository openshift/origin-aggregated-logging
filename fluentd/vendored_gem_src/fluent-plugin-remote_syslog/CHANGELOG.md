## 1.0.0

* Support fluentd-0.14 or later features [#24](https://github.com/dlackty/fluent-plugin-remote_syslog/pull/24)
* Support TCP and TLS protocol [#24](https://github.com/dlackty/fluent-plugin-remote_syslog/pull/24)
* Not support fluentd-0.12.0 from this version

## 0.3.3

* Allow override "severity" or "facility" from records [#19](https://github.com/dlackty/fluent-plugin-remote_syslog/pull/19)
* Change default port to 514 [#15](https://github.com/dlackty/fluent-plugin-remote_syslog/pull/15)

## 0.3.2

* Rewrite plugin to make rewrite tag function work properly [#4](https://github.com/dlackty/fluent-plugin-remote_syslog/pull/4)

## 0.3.1

* Fix errors in last release [#3](https://github.com/dlackty/fluent-plugin-remote_syslog/pull/3)

## 0.3.0 (yanked)

* Integrate with `Fluent::Mixin::RewriteTagName` [#2](https://github.com/dlackty/fluent-plugin-remote_syslog/pull/2)

## 0.2.1

* Fix encoding issue

## 0.2.0

* Integrate with `Fluent::Mixin::PlainTextFormatter`
* **BREAKING**: Remove `key_name` config, use `output_data_type` instead

## 0.1.0

* Initial release
