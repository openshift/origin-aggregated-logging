# Protocol::HPACK

Provides a compressor and decompressor for HTTP 2.0 headers, HPACK, as defined by [RFC7541](https://tools.ietf.org/html/rfc7541).

[![Build Status](https://secure.travis-ci.com/socketry/protocol-hpack.svg)](http://travis-ci.com/socketry/protocol-hpack)
[![Coverage Status](https://coveralls.io/repos/github/socketry/protocol-hpack/badge.svg?branch=master)](https://coveralls.io/github/socketry/protocol-hpack?branch=master)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'protocol-hpack'
```

And then execute:

	$ bundle

Or install it yourself as:

	$ gem install protocol-hpack

## Usage

### Compressing Headers

```ruby
require 'protocol/hpack'

buffer = String.new.b
compressor = Protocol::HPACK::Compressor.new(buffer)

compressor.encode([['content-length', '5']])
=> "\\\x015"
```

### Decompressing Headers

Reusing `buffer` from above:

```ruby
require 'protocol/hpack'

# Buffer from above...
buffer = "\\\x015"
decompressor = Protocol::HPACK::Decompressor.new(buffer)

decompressor.decode
=> [["content-length", "5"]]
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT license.

Copyright, 2019, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).  
Copyright, 2013, by Ilya Grigorik.  

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
