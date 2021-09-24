# -*- encoding: utf-8 -*-
# stub: activemodel 6.1.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "activemodel".freeze
  s.version = "6.1.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rails/rails/issues", "changelog_uri" => "https://github.com/rails/rails/blob/v6.1.4.1/activemodel/CHANGELOG.md", "documentation_uri" => "https://api.rubyonrails.org/v6.1.4.1/", "mailing_list_uri" => "https://discuss.rubyonrails.org/c/rubyonrails-talk", "source_code_uri" => "https://github.com/rails/rails/tree/v6.1.4.1/activemodel" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Heinemeier Hansson".freeze]
  s.date = "2021-08-19"
  s.description = "A toolkit for building modeling frameworks like Active Record. Rich support for attributes, callbacks, validations, serialization, internationalization, and testing.".freeze
  s.email = "david@loudthinking.com".freeze
  s.files = ["CHANGELOG.md".freeze, "MIT-LICENSE".freeze, "README.rdoc".freeze, "lib/active_model.rb".freeze, "lib/active_model/attribute.rb".freeze, "lib/active_model/attribute/user_provided_default.rb".freeze, "lib/active_model/attribute_assignment.rb".freeze, "lib/active_model/attribute_methods.rb".freeze, "lib/active_model/attribute_mutation_tracker.rb".freeze, "lib/active_model/attribute_set.rb".freeze, "lib/active_model/attribute_set/builder.rb".freeze, "lib/active_model/attribute_set/yaml_encoder.rb".freeze, "lib/active_model/attributes.rb".freeze, "lib/active_model/callbacks.rb".freeze, "lib/active_model/conversion.rb".freeze, "lib/active_model/dirty.rb".freeze, "lib/active_model/error.rb".freeze, "lib/active_model/errors.rb".freeze, "lib/active_model/forbidden_attributes_protection.rb".freeze, "lib/active_model/gem_version.rb".freeze, "lib/active_model/lint.rb".freeze, "lib/active_model/locale/en.yml".freeze, "lib/active_model/model.rb".freeze, "lib/active_model/naming.rb".freeze, "lib/active_model/nested_error.rb".freeze, "lib/active_model/railtie.rb".freeze, "lib/active_model/secure_password.rb".freeze, "lib/active_model/serialization.rb".freeze, "lib/active_model/serializers/json.rb".freeze, "lib/active_model/translation.rb".freeze, "lib/active_model/type.rb".freeze, "lib/active_model/type/big_integer.rb".freeze, "lib/active_model/type/binary.rb".freeze, "lib/active_model/type/boolean.rb".freeze, "lib/active_model/type/date.rb".freeze, "lib/active_model/type/date_time.rb".freeze, "lib/active_model/type/decimal.rb".freeze, "lib/active_model/type/float.rb".freeze, "lib/active_model/type/helpers.rb".freeze, "lib/active_model/type/helpers/accepts_multiparameter_time.rb".freeze, "lib/active_model/type/helpers/mutable.rb".freeze, "lib/active_model/type/helpers/numeric.rb".freeze, "lib/active_model/type/helpers/time_value.rb".freeze, "lib/active_model/type/helpers/timezone.rb".freeze, "lib/active_model/type/immutable_string.rb".freeze, "lib/active_model/type/integer.rb".freeze, "lib/active_model/type/registry.rb".freeze, "lib/active_model/type/string.rb".freeze, "lib/active_model/type/time.rb".freeze, "lib/active_model/type/value.rb".freeze, "lib/active_model/validations.rb".freeze, "lib/active_model/validations/absence.rb".freeze, "lib/active_model/validations/acceptance.rb".freeze, "lib/active_model/validations/callbacks.rb".freeze, "lib/active_model/validations/clusivity.rb".freeze, "lib/active_model/validations/confirmation.rb".freeze, "lib/active_model/validations/exclusion.rb".freeze, "lib/active_model/validations/format.rb".freeze, "lib/active_model/validations/helper_methods.rb".freeze, "lib/active_model/validations/inclusion.rb".freeze, "lib/active_model/validations/length.rb".freeze, "lib/active_model/validations/numericality.rb".freeze, "lib/active_model/validations/presence.rb".freeze, "lib/active_model/validations/validates.rb".freeze, "lib/active_model/validations/with.rb".freeze, "lib/active_model/validator.rb".freeze, "lib/active_model/version.rb".freeze]
  s.homepage = "https://rubyonrails.org".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.0.9".freeze
  s.summary = "A toolkit for building modeling frameworks (part of Rails).".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>.freeze, ["= 6.1.4.1"])
    else
      s.add_dependency(%q<activesupport>.freeze, ["= 6.1.4.1"])
    end
  else
    s.add_dependency(%q<activesupport>.freeze, ["= 6.1.4.1"])
  end
end

