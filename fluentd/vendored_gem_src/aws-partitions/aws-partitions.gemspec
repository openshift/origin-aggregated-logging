# -*- encoding: utf-8 -*-
# stub: aws-partitions 1.296.0 ruby lib

Gem::Specification.new do |s|
  s.name = "aws-partitions".freeze
  s.version = "1.296.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/aws/aws-sdk-ruby/tree/master/gems/aws-partitions/CHANGELOG.md", "source_code_uri" => "https://github.com/aws/aws-sdk-ruby/tree/master/gems/aws-partitions" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Amazon Web Services".freeze]
  s.date = "2020-04-08"
  s.description = "Provides interfaces to enumerate AWS partitions, regions, and services.".freeze
  s.files = ["lib/aws-partitions.rb".freeze, "lib/aws-partitions/endpoint_provider.rb".freeze, "lib/aws-partitions/partition.rb".freeze, "lib/aws-partitions/partition_list.rb".freeze, "lib/aws-partitions/region.rb".freeze, "lib/aws-partitions/service.rb".freeze, "partitions.json".freeze]
  s.homepage = "https://github.com/aws/aws-sdk-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Provides information about AWS partitions, regions, and services.".freeze
end

