# Strptime

[![Build Status](https://travis-ci.org/nurse/strptime.png)](https://travis-ci.org/nurse/strptime)
[![Build status](https://ci.appveyor.com/api/projects/status/9wr116l8uy1bdcxf/branch/master?svg=true)](https://ci.appveyor.com/project/nurse/strptime/branch/master)


Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/strptime`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'strptime'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install strptime

## Usage

### Strptime for time parsing

```ruby
require 'strptime'
parser = Strptime.new('%Y-%m-%dT%H:%M:%S%z')
parser.exec('2015-12-25T12:34:56+09') #=> 2015-12-25 12:34:56 +09:00
parser.execi('2015-12-25T12:34:56+09') #=> 1451014496
```

### Strftime for time formatting

```ruby
require 'strptime'
now = Time.now
formatter = Strftime.new('%Y-%m-%dT%H:%M:%S.%L %z')
formatter.exec(now)        # 2017-12-29T07:24:31.505 +0900
formatter.execi(now.to_i)  # 2017-12-28T22:24:31.000 +0000
```

## Contributing

1. Fork it ( https://github.com/nurse/strptime/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
