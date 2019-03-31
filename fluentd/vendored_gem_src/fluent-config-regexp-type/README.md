# fluent-config-regexp-type
[![Build Status](https://travis-ci.org/okkez/fluent-config-regexp-type.svg?branch=master)](https://travis-ci.org/okkez/fluent-config-regexp-type)

Fluentd 1.2.0 supports regexp type in `config_param`.
This gem backports regexp type for `config_param`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fluent-config-regexp-type'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-config-regexp-type

## Usage

```ruby
require "fluent/plugin/output"
# Load this library's monkey patch
require "fluent/config/regexp_type"

class Fluent::Plugin::SampleOutput < Fluent::Plugin::Output
  Fluent::Plugin.register_output('rewrite_tag_filter', self)
  
  config_param :pattern, :regexp
  
  def process(tag, es)
    # ...
  end
end

```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/okkez/fluent-config-regexp-type.

## License

Apache License, Version 2.0
