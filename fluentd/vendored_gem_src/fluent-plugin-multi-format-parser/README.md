# Multi format parser plugin for Fluentd

Parse format mixed logs.

## Requirements

| fluent-plugin-multi-format-parser | fluentd | ruby |
|-------------------|---------|------|
| >= 1.0.0 | >= v0.14.0 | >= 2.1 |
|  < 1.0.0 | >= v0.12.0 | >= 1.9 |

## Installation

Use RubyGems:

    fluent-gem install fluent-plugin-multi-format-parser

## Configuration

This plugin is a parser plugin. After installed, you can use `multi_format` in `<parse>` supported plugins.
Use multiple `<pattern>`s to specify multiple parser formats.

    <source>
      @type udp
      tag logs.multi

      <parse>
        @type multi_format
        <pattern>
          format apache
        </pattern>
        <pattern>
          format json
          time_key timestamp
        </pattern>
        <pattern>
          format none
        </pattern>
      </parse>
    </source>

`multi_format` tries pattern matching from top to bottom and returns parsed result when matched.

Available format patterns and parameters are depends on Fluentd parsers.
See [parser plugin document](http://docs.fluentd.org/v1.0/articles/parser-plugin-overview) for more details.

### For v1.0/v0.14

Put `<pattern>`s inside `<parse>`.

    <filter app.**>
      @type parser
      key_name message
      <parse>
        @type multi_format
        <pattern>
          format json
        </pattern>
        <pattern>
          format regexp
          expression /...your regexp pattern.../
        </pattern>
        <pattern>
          format none
        </pattern>
      </parse>
    </filter>

### For v0.12

Use `format` instead of `<parse></parse>`.

    <filter app.**>
      @type parser
      key_name message

      format multi_format
      <pattern>
        format json
      </pattern>
      <pattern>
        format /...your regexp pattern.../
      </pattern>
      <pattern>
        format none
      </pattern>
    </filter>

### NOTE

This plugin doesn't work with `multiline` parsers because parser itself doesn't store previous lines.

## Copyright

<table>
  <tr>
    <td>Author</td><td>Masahiro Nakagawa <repeatedly@gmail.com></td>
  </tr>
  <tr>
    <td>Copyright</td><td>Copyright (c) 2014- Masahiro Nakagawa</td>
  </tr>
  <tr>
    <td>License</td><td>MIT License</td>
  </tr>
</table>
