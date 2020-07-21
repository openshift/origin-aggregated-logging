# ruby-proxifier

## Installing

### Recommended

```
gem install proxifier
```

### Edge

```
git clone https://github.com/samuelkadolph/ruby-proxifier
cd ruby-proxifier && rake install
```

## Rationale

This gem was created for 2 purposes.

First is to enable ruby programmers to use HTTP or SOCKS proxies
interchangeably when using TCPSockets. Either manually with
`Proxifier::Proxy#open` or by `require "proxifier/env"`.

The second purpose is to use ruby code that doesn't user proxies for users that
have to use proxies.<br>The pruby and pirb executables are simple wrappers for
their respective ruby executables that support proxies from environment
variables.

## Usage

### Executable Wrappers & Environment Variables

proxifier provides two executables: `pruby` and `pirb`. They are simple
wrappers for your current `ruby` and `irb` executables that requires the
`"proxifier/env"` script which installs hooks into `TCPSocket` which will use
the proxy environment variables to proxy any `TCPSocket`.

The environment variables that proxifier will check are (in order of descending
precedence):

<table>
  <tr>
    <th>Variable Name</th>
    <th>Alternatives</th>
    <th>Notes</th>
  </tr>
  <tr>
    <td>proxy</td>
    <td>PROXY</td>
    <td>Requires the proxy scheme to be present.</td>
  </tr>
  <tr>
    <td>socks_proxy</td>
    <td>SOCKS_PROXY<br>socks5_proxy<br>SOCKS5_PROXY</td>
    <td>Implies the SOCKS5 proxy scheme.</td>
  </tr>
  <tr>
    <td>socks4a_proxy</td>
    <td>SOCKS4A_PROXY</td>
    <td>Implies the SOCKS4A proxy scheme.</td>
  </tr>
  <tr>
    <td>socks4_proxy</td>
    <td>PROXY</td>
    <td>Implies the SOCKS4 proxy scheme.</td>
  </tr>
  <tr>
    <td>http_proxy</td>
    <td>HTTP_PROXY</td>
    <td>Implies the HTTP proxy scheme.</td>
  </tr>
</table>

### Ruby

```ruby
require "proxifier/proxy"

proxy = Proxifier::Proxy("socks://localhost")
socket = proxy.open("www.google.com", 80)
socket << "GET / HTTP/1.1\r\nHost: www.google.com\r\n\r\n"
socket.gets # => "HTTP/1.1 200 OK\r\n"
```

## Supported Proxies

<table>
  <tr>
    <th>Protocol</th>
    <th>Formats</th>
    <th>Notes</th>
  </tr>
  <tr>
    <td>HTTP</td>
    <td><pre>http://[username[:password]@]host[:port][?tunnel=false]</pre></td>
    <td>
      The port defaults to 80. This is currently a limitation that may be solved in the future.<br>
      Appending <code>?tunnel=false</code> forces the proxy to not use <code>CONNECT</code>.</td>
  </tr>
  <tr>
    <td>SOCKS5</td>
    <td><pre>socks://[username[:password]@]host[:port]
socks5://[username[:password]@]host[:port]</pre></td>
    <td>
      Port defaults to 1080.
    </td>
  </tr>
  <tr>
    <td>SOCKS4A</td>
    <td><pre>socks4a://[username@]host[:port]</pre></td>
    <td>Not yet implemented.</td>
  </tr>
  <tr>
    <td>SOCKS4</td>
    <td><pre>socks4://[username@]host[:port]</pre></td>
    <td>Currently hangs. Not sure if the problem is with code or server.</td>
  </tr>
</table>
