# -*- encoding: utf-8 -*-
# stub: faraday 0.17.3 ruby lib

Gem::Specification.new do |s|
  s.name = "faraday".freeze
  s.version = "0.17.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/lostisland/faraday/issues", "changelog_uri" => "https://github.com/lostisland/faraday/blob/master/CHANGELOG.md", "homepage_uri" => "https://lostisland.github.io/faraday", "source_code_uri" => "https://github.com/lostisland/faraday/" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["@technoweenie".freeze, "@iMacTia".freeze, "@olleolleolle".freeze]
  s.date = "2019-12-31"
  s.email = "technoweenie@gmail.com".freeze
  s.files = ["CHANGELOG.md".freeze, "LICENSE.md".freeze, "README.md".freeze, "Rakefile".freeze, "lib/faraday.rb".freeze, "lib/faraday/adapter.rb".freeze, "lib/faraday/adapter/em_http.rb".freeze, "lib/faraday/adapter/em_http_ssl_patch.rb".freeze, "lib/faraday/adapter/em_synchrony.rb".freeze, "lib/faraday/adapter/em_synchrony/parallel_manager.rb".freeze, "lib/faraday/adapter/excon.rb".freeze, "lib/faraday/adapter/httpclient.rb".freeze, "lib/faraday/adapter/net_http.rb".freeze, "lib/faraday/adapter/net_http_persistent.rb".freeze, "lib/faraday/adapter/patron.rb".freeze, "lib/faraday/adapter/rack.rb".freeze, "lib/faraday/adapter/test.rb".freeze, "lib/faraday/adapter/typhoeus.rb".freeze, "lib/faraday/autoload.rb".freeze, "lib/faraday/connection.rb".freeze, "lib/faraday/deprecate.rb".freeze, "lib/faraday/error.rb".freeze, "lib/faraday/middleware.rb".freeze, "lib/faraday/options.rb".freeze, "lib/faraday/parameters.rb".freeze, "lib/faraday/rack_builder.rb".freeze, "lib/faraday/request.rb".freeze, "lib/faraday/request/authorization.rb".freeze, "lib/faraday/request/basic_authentication.rb".freeze, "lib/faraday/request/instrumentation.rb".freeze, "lib/faraday/request/multipart.rb".freeze, "lib/faraday/request/retry.rb".freeze, "lib/faraday/request/token_authentication.rb".freeze, "lib/faraday/request/url_encoded.rb".freeze, "lib/faraday/response.rb".freeze, "lib/faraday/response/logger.rb".freeze, "lib/faraday/response/raise_error.rb".freeze, "lib/faraday/upload_io.rb".freeze, "lib/faraday/utils.rb".freeze, "spec/faraday/deprecate_spec.rb".freeze, "spec/faraday/error_spec.rb".freeze, "spec/faraday/response/raise_error_spec.rb".freeze, "spec/spec_helper.rb".freeze, "test/adapters/default_test.rb".freeze, "test/adapters/em_http_test.rb".freeze, "test/adapters/em_synchrony_test.rb".freeze, "test/adapters/excon_test.rb".freeze, "test/adapters/httpclient_test.rb".freeze, "test/adapters/integration.rb".freeze, "test/adapters/logger_test.rb".freeze, "test/adapters/net_http_persistent_test.rb".freeze, "test/adapters/net_http_test.rb".freeze, "test/adapters/patron_test.rb".freeze, "test/adapters/rack_test.rb".freeze, "test/adapters/test_middleware_test.rb".freeze, "test/adapters/typhoeus_test.rb".freeze, "test/authentication_middleware_test.rb".freeze, "test/composite_read_io_test.rb".freeze, "test/connection_test.rb".freeze, "test/env_test.rb".freeze, "test/helper.rb".freeze, "test/live_server.rb".freeze, "test/middleware/instrumentation_test.rb".freeze, "test/middleware/retry_test.rb".freeze, "test/middleware_stack_test.rb".freeze, "test/multibyte.txt".freeze, "test/options_test.rb".freeze, "test/parameters_test.rb".freeze, "test/request_middleware_test.rb".freeze, "test/response_middleware_test.rb".freeze, "test/strawberry.rb".freeze, "test/utils_test.rb".freeze]
  s.homepage = "https://lostisland.github.io/faraday".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "HTTP/REST API client library.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<multipart-post>.freeze, [">= 1.2", "< 3"])
    else
      s.add_dependency(%q<multipart-post>.freeze, [">= 1.2", "< 3"])
    end
  else
    s.add_dependency(%q<multipart-post>.freeze, [">= 1.2", "< 3"])
  end
end

