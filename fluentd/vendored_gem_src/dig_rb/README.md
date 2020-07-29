# Dig_rb

[![Gem Version](https://badge.fury.io/rb/dig_rb.svg)](https://badge.fury.io/rb/dig_rb) [![Build Status](https://travis-ci.org/jrochkind/dig_rb.svg?branch=master)](https://travis-ci.org/jrochkind/dig_rb)

[Ruby 2.3.0 introduced #dig on Hash, Array, and Struct](https://www.ruby-lang.org/en/news/2015/12/25/ruby-2-3-0-released/). With this gem, you can have dig on ruby pre 2.3.0, or any ruby lacking dig.

If you are writing an app and want to use dig in it you should probably just upgrade to ruby 2.3.0. But if you are writing a gem and want it to work with both MRI 2.3.0 and others (including JRuby 9.0.x), this gem is for you. This gem only adds #dig methods if they aren't already defined, so it's safe to use in code that is for all rubies, if run on MRI 2.3.0 you'll still be using native #dig, otherwise dig_rb's implementation.

### Will it work identically to MRI 2.3.0 dig?

Dig_rb is tested with:

* Specs found in MRI repo for #dig in 2.3.0
* [Ruby Spec Suite](https://github.com/ruby/spec/) specs found in repo for Array and Hash#dig
* All examples in MRI 2.3.0 generated method API docs. (One example in MRI 2.3.0 is _wrong_ about exception class and message returned, dig_rb matches actual 2.3.0 behavior there, not documented example)

[Our travis](https://travis-ci.org/jrochkind/dig_rb) runs tests on a variety of ruby platforms. 

If you find any weird edge cases that work differenty in MRI 2.3.0 than in ruby_dig, let me know in a GitHub Issue please.

The performance of dig_rb will probably be less than native MRI 2.3.0 implementation, this code is not written for performance. But it should
be fine, really.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dig_rb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dig_rb

## Usage

Just go ahead and use #dig as doc'd in MRI 2.3.0, now it'll work on any ruby.

* [Hash](http://ruby-doc.org/core-2.3.0/Hash.html#method-i-dig)
* [Array](http://ruby-doc.org/core-2.3.0/Array.html#method-i-dig)
* [Struct](http://ruby-doc.org/core-2.3.0/Struct.html#method-i-dig)
* [OpenStruct](http://ruby-doc.org/stdlib-2.3.0/libdoc/ostruct/rdoc/OpenStruct.html#method-i-dig)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/jrochkind/dig_rb/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
