# Filter plugin to modify event record for [Fluentd](http://fluentd.org)

Adding arbitary field to event record without customizing existence plugin.

For example, generated event from *in_tail* doesn't contain "hostname" of running machine.
In this case, you can use *record_modifier* to add "hostname" field to event record.

## Requirements

| fluent-plugin-record-modifier  | fluentd | ruby |
|--------------------------------|---------|------|
| >= 2.0.0 | >= v1.0.0  | >= 2.1 |
| >= 1.0.0 | >= v0.14.0 | >= 2.1 |
|  < 1.0.0 | >= v0.12.0 | >= 1.9 |

## Installation

Use RubyGems:

    fluent-gem install fluent-plugin-record-modifier --no-document

## Configuration

Use `record_modifier` filter.

    <filter pattern>
      @type record_modifier

      <record>
        gen_host "#{Socket.gethostname}"
        foo bar
      </record>
    </filter>

If following record is passed:

```js
{"message":"hello world!"}
```

then you got new record like below:

```js
{"message":"hello world!", "gen_host":"oreore-mac.local", "foo":"bar"}
```

You can also use `record_transformer` like `${xxx}` placeholders and access `tag`, `time`, `record` and `tag_parts` values by Ruby code.

    <filter pattern>
      @type record_modifier

      <record>
        tag ${tag}
        tag_extract ${tag_parts[0]}-${tag_parts[1]}-foo
        formatted_time ${Time.at(time).to_s}
        new_field foo:${record['key1'] + record['dict']['key']} 
      </record>
    </filter>

`record_modifier` is faster than `record_transformer`. See [this comment](https://github.com/repeatedly/fluent-plugin-record-modifier/pull/7#issuecomment-169843012).
But unlike `record_transformer`, `record_modifier` doesn't support following features for now.

- tag_suffix and tag_prefix
- dynamic key placeholder

### prepare_value

Prepare values for filtering. This ruby code is evaluated in `configure` phase and prepared values can be used in `<record>`. Here is an example:

    <filter pattern>
      @type record_modifier
      prepare_value require 'foo'; @foo = Foo.new
      <record>
        key ${@foo.method1}
      </record>
    </filter>

This feature is useful for using external library.

### char_encoding

Fluentd including some plugins treats logs as a BINARY by default to forward.
But a user sometimes wants to process logs depends on their requirements, e.g. handling char encoding correctly.

`char_encoding` parameter is useful for this case.

```conf
<filter pattern>
  @type record_modifier

  # set UTF-8 encoding information to string.
  char_encoding utf-8

  # change char encoding from 'UTF-8' to 'EUC-JP'
  char_encoding utf-8:euc-jp
</filter>
```

In `char_encoding from:to` case, it replaces invalid character with safe character.

### remove_keys

The logs include needless record keys in some cases.
You can remove it by using `remove_keys` parameter.

```conf
<filter pattern>
  @type record_modifier

  # remove key1 and key2 keys from record
  remove_keys key1,key2
</filter>
```

If following record is passed:

```js
{"key1":"hoge", "key2":"foo", "key3":"bar"}
```

then you got new record like below:

```js
{"key3":"bar"}
```

### whitelist_keys

If you want to handle the set of explicitly specified keys, you can use `whitelist_keys` of this plugin. It's exclusive with `remove_keys`.

```conf
<filter pattern>
  @type record_modifier

  # remove all keys except for key1 and key2
  whitelist_keys key1,key2
</filter>
```

If following record is passed:

```js
{"key1":"hoge", "key2":"foo", "key3":"bar"}
```

then you got new record like below:

```js
{"key1":"hoge", "key2":"foo"}
```

### replace_keys_value

If you want to replace specific value for keys you can use `replace` section.

```conf
<filter pattern>
  @type record_modifier

  # replace key key1
  <replace>
    # your key name
    key key1
    # your regexp
    expression /^(?<start>.+).{2}(?<end>.+)$/
    # replace string
    replace \\k<start>ors\\k<end>
  </replace>
  # replace key key2
  <replace>
    # your key name
    key key2
    # your regexp
    expression /^(.{1}).{2}(.{1})$/
    # replace string
    replace \\1ors\\2
  </replace>
</filter>
```

If following record is passed:

```js
{"key1":"hoge", "key2":"hoge", "key3":"bar"}
```

then you got new record like below:

```js
{"key1":"horse", "key2":"horse", "key3":"bar"}
```


### Ruby code trick for complex logic

If you need own complex logic in filter, writing filter plugin is better. But if you don't want to write new plugin, you can use temporal key trick like below:

```
<filter reform.**>
  @type record_modifier
  remove_keys _dummy_
  <record>
    _dummy_ ${if record.has_key?('foo'); record['bar'] = 'Hi!'; end; nil}
  </record>
</filter>}
```

### record_modifier output

Output plugin version of `record_modifier` filter. If you want to process events and change tag at the same time, this plugin is useful.

    <match pattern>
      @type record_modifier
      tag foo.${record["field1"]}

      <record>
        gen_host "#{Socket.gethostname}"
        foo bar
      </record>
    </match>

## Copyright

<table>
  <tr>
    <td>Author</td><td>Masahiro Nakagawa <repeatedly@gmail.com></td>
  </tr>
  <tr>
    <td>Copyright</td><td>Copyright (c) 2013- Masahiro Nakagawa</td>
  </tr>
  <tr>
    <td>License</td><td>MIT License</td>
  </tr>
</table>
