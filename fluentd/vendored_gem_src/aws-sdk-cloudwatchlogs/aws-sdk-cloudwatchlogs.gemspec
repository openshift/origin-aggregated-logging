# -*- encoding: utf-8 -*-
# stub: aws-sdk-cloudwatchlogs 1.45.0 ruby lib

Gem::Specification.new do |s|
  s.name = "aws-sdk-cloudwatchlogs".freeze
  s.version = "1.45.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/aws/aws-sdk-ruby/tree/version-3/gems/aws-sdk-cloudwatchlogs/CHANGELOG.md", "source_code_uri" => "https://github.com/aws/aws-sdk-ruby/tree/version-3/gems/aws-sdk-cloudwatchlogs" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Amazon Web Services".freeze]
  s.date = "2021-09-01"
  s.description = "Official AWS Ruby gem for Amazon CloudWatch Logs. This gem is part of the AWS SDK for Ruby.".freeze
  s.email = ["aws-dr-rubygems@amazon.com".freeze]
  s.files = ["CHANGELOG.md".freeze, "LICENSE.txt".freeze, "VERSION".freeze, "lib/aws-sdk-cloudwatchlogs.rb".freeze, "lib/aws-sdk-cloudwatchlogs/client.rb".freeze, "lib/aws-sdk-cloudwatchlogs/client_api.rb".freeze, "lib/aws-sdk-cloudwatchlogs/customizations.rb".freeze, "lib/aws-sdk-cloudwatchlogs/errors.rb".freeze, "lib/aws-sdk-cloudwatchlogs/resource.rb".freeze, "lib/aws-sdk-cloudwatchlogs/types.rb".freeze]
  s.homepage = "https://github.com/aws/aws-sdk-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "3.0.9".freeze
  s.summary = "AWS SDK for Ruby - Amazon CloudWatch Logs".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<aws-sdk-core>.freeze, ["~> 3", ">= 3.120.0"])
      s.add_runtime_dependency(%q<aws-sigv4>.freeze, ["~> 1.1"])
    else
      s.add_dependency(%q<aws-sdk-core>.freeze, ["~> 3", ">= 3.120.0"])
      s.add_dependency(%q<aws-sigv4>.freeze, ["~> 1.1"])
    end
  else
    s.add_dependency(%q<aws-sdk-core>.freeze, ["~> 3", ">= 3.120.0"])
    s.add_dependency(%q<aws-sigv4>.freeze, ["~> 1.1"])
  end
end

