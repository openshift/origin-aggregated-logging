# -*- encoding: utf-8 -*-
# stub: net-http-persistent 3.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "net-http-persistent".freeze
  s.version = "3.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Eric Hodel".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDNjCCAh6gAwIBAgIBBjANBgkqhkiG9w0BAQsFADBBMRAwDgYDVQQDDAdkcmJy\nYWluMRgwFgYKCZImiZPyLGQBGRYIc2VnbWVudDcxEzARBgoJkiaJk/IsZAEZFgNu\nZXQwHhcNMTkwNDA4MjEwOTU2WhcNMjAwNDA3MjEwOTU2WjBBMRAwDgYDVQQDDAdk\ncmJyYWluMRgwFgYKCZImiZPyLGQBGRYIc2VnbWVudDcxEzARBgoJkiaJk/IsZAEZ\nFgNuZXQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCbbgLrGLGIDE76\nLV/cvxdEzCuYuS3oG9PrSZnuDweySUfdp/so0cDq+j8bqy6OzZSw07gdjwFMSd6J\nU5ddZCVywn5nnAQ+Ui7jMW54CYt5/H6f2US6U0hQOjJR6cpfiymgxGdfyTiVcvTm\nGj/okWrQl0NjYOYBpDi+9PPmaH2RmLJu0dB/NylsDnW5j6yN1BEI8MfJRR+HRKZY\nmUtgzBwF1V4KIZQ8EuL6I/nHVu07i6IkrpAgxpXUfdJQJi0oZAqXurAV3yTxkFwd\ng62YrrW26mDe+pZBzR6bpLE+PmXCzz7UxUq3AE0gPHbiMXie3EFE0oxnsU3lIduh\nsCANiQ8BAgMBAAGjOTA3MAkGA1UdEwQCMAAwCwYDVR0PBAQDAgSwMB0GA1UdDgQW\nBBS5k4Z75VSpdM0AclG2UvzFA/VW5DANBgkqhkiG9w0BAQsFAAOCAQEAP5FfXeij\n/fkvIZDdN0LV1ES3Thqoz4aQFbJv1Gf3VccYMs7/Rop5oWBOtiHMIVc855bgv5fx\nuzRtuwiuiq1mZ6IZWkFnEw+vi+M6Q5e/8v+dhej1r7rPW71y4I1wH972O8qiuRXZ\nEVu1y+fPhNAu6OTMgVtgkijEuA9d4OQ2xusF/YKWkaVkjrdHcDAEaquxYUKrswxM\nDohqfAYWGDt2dmCWfRWTsBLm3p3R0mwKe8uOy4gSwcvG5SG57oSZoxrAN9CgsJoR\nP+3YOaiDtZ7g4lYXhpJrMooDnoWr4TPbGIVuq0xfPlFinjBH0o1W+LfGS+3aCN6b\njT8g+1iKSQKJYA==\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2019-07-25"
  s.description = "Manages persistent connections using Net::HTTP plus a speed fix for Ruby 1.8.\nIt's thread-safe too!\n\nUsing persistent HTTP connections can dramatically increase the speed of HTTP.\nCreating a new HTTP connection for every request involves an extra TCP\nround-trip and causes TCP congestion avoidance negotiation to start over.\n\nNet::HTTP supports persistent connections with some API methods but does not\nhandle reconnection gracefully.  Net::HTTP::Persistent supports reconnection\nand retry according to RFC 2616.".freeze
  s.email = ["drbrain@segment7.net".freeze]
  s.extra_rdoc_files = ["History.txt".freeze, "Manifest.txt".freeze, "README.rdoc".freeze]
  s.files = [".autotest".freeze, ".gemtest".freeze, ".travis.yml".freeze, "Gemfile".freeze, "History.txt".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "Rakefile".freeze, "lib/net/http/persistent.rb".freeze, "lib/net/http/persistent/connection.rb".freeze, "lib/net/http/persistent/pool.rb".freeze, "lib/net/http/persistent/timed_stack_multi.rb".freeze, "test/test_net_http_persistent.rb".freeze, "test/test_net_http_persistent_timed_stack_multi.rb".freeze]
  s.homepage = "http://docs.seattlerb.org/net-http-persistent".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new("~> 2.1".freeze)
  s.rubygems_version = "3.0.9".freeze
  s.summary = "Manages persistent connections using Net::HTTP plus a speed fix for Ruby 1.8".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<connection_pool>.freeze, ["~> 2.2"])
      s.add_development_dependency(%q<minitest>.freeze, ["~> 5.11"])
      s.add_development_dependency(%q<hoe-bundler>.freeze, ["~> 1.5"])
      s.add_development_dependency(%q<hoe-travis>.freeze, ["~> 1.4", ">= 1.4.1"])
      s.add_development_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 3.17"])
    else
      s.add_dependency(%q<connection_pool>.freeze, ["~> 2.2"])
      s.add_dependency(%q<minitest>.freeze, ["~> 5.11"])
      s.add_dependency(%q<hoe-bundler>.freeze, ["~> 1.5"])
      s.add_dependency(%q<hoe-travis>.freeze, ["~> 1.4", ">= 1.4.1"])
      s.add_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
      s.add_dependency(%q<hoe>.freeze, ["~> 3.17"])
    end
  else
    s.add_dependency(%q<connection_pool>.freeze, ["~> 2.2"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.11"])
    s.add_dependency(%q<hoe-bundler>.freeze, ["~> 1.5"])
    s.add_dependency(%q<hoe-travis>.freeze, ["~> 1.4", ">= 1.4.1"])
    s.add_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.17"])
  end
end

