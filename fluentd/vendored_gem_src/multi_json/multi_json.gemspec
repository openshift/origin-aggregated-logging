# -*- encoding: utf-8 -*-
# stub: multi_json 1.15.0 ruby lib

Gem::Specification.new do |s|
  s.name = "multi_json".freeze
  s.version = "1.15.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/intridea/multi_json/issues", "changelog_uri" => "https://github.com/intridea/multi_json/blob/v1.15.0/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/multi_json/1.15.0", "source_code_uri" => "https://github.com/intridea/multi_json/tree/v1.15.0", "wiki_uri" => "https://github.com/intridea/multi_json/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Bleigh".freeze, "Josh Kalderimis".freeze, "Erik Michaels-Ober".freeze, "Pavel Pravosud".freeze]
  s.date = "2020-07-10"
  s.description = "A common interface to multiple JSON libraries, including Oj, Yajl, the JSON gem (with C-extensions), the pure-Ruby JSON gem, NSJSONSerialization, gson.rb, JrJackson, and OkJson.".freeze
  s.email = ["michael@intridea.com".freeze, "josh.kalderimis@gmail.com".freeze, "sferik@gmail.com".freeze, "pavel@pravosud.com".freeze]
  s.files = ["CHANGELOG.md".freeze, "CONTRIBUTING.md".freeze, "LICENSE.md".freeze, "README.md".freeze, "lib/multi_json.rb".freeze, "lib/multi_json/adapter.rb".freeze, "lib/multi_json/adapter_error.rb".freeze, "lib/multi_json/adapters/gson.rb".freeze, "lib/multi_json/adapters/jr_jackson.rb".freeze, "lib/multi_json/adapters/json_common.rb".freeze, "lib/multi_json/adapters/json_gem.rb".freeze, "lib/multi_json/adapters/json_pure.rb".freeze, "lib/multi_json/adapters/nsjsonserialization.rb".freeze, "lib/multi_json/adapters/oj.rb".freeze, "lib/multi_json/adapters/ok_json.rb".freeze, "lib/multi_json/adapters/yajl.rb".freeze, "lib/multi_json/convertible_hash_keys.rb".freeze, "lib/multi_json/options.rb".freeze, "lib/multi_json/options_cache.rb".freeze, "lib/multi_json/parse_error.rb".freeze, "lib/multi_json/vendor/okjson.rb".freeze, "lib/multi_json/version.rb".freeze]
  s.homepage = "https://github.com/intridea/multi_json".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.4".freeze
  s.summary = "A common interface to multiple JSON libraries.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rake>.freeze, ["~> 10.5"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.9"])
  else
    s.add_dependency(%q<rake>.freeze, ["~> 10.5"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.9"])
  end
end

