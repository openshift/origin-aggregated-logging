# -*- encoding: utf-8 -*-
# stub: aws-eventstream 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "aws-eventstream".freeze
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/aws/aws-sdk-ruby/tree/master/gems/aws-eventstream/CHANGELOG.md", "source_code_uri" => "https://github.com/aws/aws-sdk-ruby/tree/master/gems/aws-eventstream" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Amazon Web Services".freeze]
  s.date = "2020-04-08"
  s.description = "Amazon Web Services event stream library. Decodes and encodes binary stream under `vnd.amazon.event-stream` content-type".freeze
  s.files = ["lib/aws-eventstream.rb".freeze, "lib/aws-eventstream/decoder.rb".freeze, "lib/aws-eventstream/encoder.rb".freeze, "lib/aws-eventstream/errors.rb".freeze, "lib/aws-eventstream/header_value.rb".freeze, "lib/aws-eventstream/message.rb".freeze, "lib/aws-eventstream/types.rb".freeze]
  s.homepage = "https://github.com/aws/aws-sdk-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "AWS Event Stream Library".freeze
end

