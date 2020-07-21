# Resolve::Hostname

`Resolve::Hostname` is hostname resolver with:

* caching with specified TTL
* reloading of name server configurations (ex: `/etc/resolv.conf`)
* skipping system resolver (default) or not when specified
* primary IP address version specification (default: IPv4)

## Installation

Add this line to your application's Gemfile:

    gem 'resolve-hostname'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resolve-hostname

## Usage

    require 'resolve/hostname'
    
    resolver = Resolve::Hostname.new
    resolver.getaddress('www.google.com') #=> "173.194.72.103"
    resolver.getaddress('www.google.com') #=> "173.194.72.103" # from cache

Cache TTL(seconds) setting available for each resolver instances like this:

    r = Resolve::Hostname.new(:ttl => 10) # default 60 seconds

    r.getaddress('www.example.com')
    sleep 11
    r.getaddress('www.example.com') # not from cache, but from actual dns record (and cached)

You can specify `resolver_ttl` with expectation for re-reading of `/etc/resolv.conf` in long life daemons.

    r = Resolve::Hostname.new(:ttl => 10, :resolver_ttl => 20)
    r.getaddress('www.example.com')

Resolver raises `Resolve::Hostname::NotFoundError` when any records be found, and you can stop it (nil returned):

    r1 = Resolve::Hostname.new
    r1.getaddress('does-not-exists.example.com') # Resolve::Hostname::NotFoundError raised
    
    r2 = Resolve::Hostname.new(:raise_notfound => false)
    r2.getaddress('does-not-exists.example.com') #=> nil

### System Resolver

for `/etc/hosts`:

    r = Resolve::Hostname.new(:system_resolver => true)
    r.getaddress('my-db-server.local')

### IPv6 address query

For queries about IPv6 addresses:

    r = Resolve::Hostname.new(:version => :ipv6)
    r.getaddress('example.com')          #=> '2001:500:88:200::10'
    r.getaddress('ipv4only.example.com') #=> '192.0.43.10'

### To deny other version of IP address

Specify `:permit_other_version => false` if you are in IPv4 network and want not to get IPv6 address:

    r1 = Resolve::Hostname.new
    r1.getaddress('ipv6only.example.com') #=> '2001:500:88:200::10'
    
    r2 = Resolve::Hostname.new(:version => :ipv4, :permit_other_version => false)
    r2.getaddress('ipv6only.example.com') # Resolve::Hostname::NotFoundError raised

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## TODO

* negative cache support
* DNS round robin support

## Copyright

* [MIT License](http://www.opensource.org/licenses/MIT).
* Copyright (c) 2013- TAGOMORI Satoshi (tagomoris)
