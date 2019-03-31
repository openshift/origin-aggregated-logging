# -*- encoding: utf-8 -*-
# stub: i18n 1.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "i18n".freeze
  s.version = "1.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/svenfuchs/i18n/issues", "changelog_uri" => "https://github.com/svenfuchs/i18n/releases", "documentation_uri" => "https://guides.rubyonrails.org/i18n.html", "source_code_uri" => "https://github.com/svenfuchs/i18n" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sven Fuchs".freeze, "Joshua Harvey".freeze, "Matt Aimonetti".freeze, "Stephan Soller".freeze, "Saimon Moore".freeze, "Ryan Bigg".freeze]
  s.date = "2019-03-03"
  s.description = "New wave Internationalization support for Ruby.".freeze
  s.email = "rails-i18n@googlegroups.com".freeze
  s.files = ["MIT-LICENSE".freeze, "README.md".freeze, "lib/i18n.rb".freeze, "lib/i18n/backend.rb".freeze, "lib/i18n/backend/base.rb".freeze, "lib/i18n/backend/cache.rb".freeze, "lib/i18n/backend/cache_file.rb".freeze, "lib/i18n/backend/cascade.rb".freeze, "lib/i18n/backend/chain.rb".freeze, "lib/i18n/backend/fallbacks.rb".freeze, "lib/i18n/backend/flatten.rb".freeze, "lib/i18n/backend/gettext.rb".freeze, "lib/i18n/backend/interpolation_compiler.rb".freeze, "lib/i18n/backend/key_value.rb".freeze, "lib/i18n/backend/memoize.rb".freeze, "lib/i18n/backend/metadata.rb".freeze, "lib/i18n/backend/pluralization.rb".freeze, "lib/i18n/backend/simple.rb".freeze, "lib/i18n/backend/transliterator.rb".freeze, "lib/i18n/config.rb".freeze, "lib/i18n/core_ext/hash.rb".freeze, "lib/i18n/exceptions.rb".freeze, "lib/i18n/gettext.rb".freeze, "lib/i18n/gettext/helpers.rb".freeze, "lib/i18n/gettext/po_parser.rb".freeze, "lib/i18n/interpolate/ruby.rb".freeze, "lib/i18n/locale.rb".freeze, "lib/i18n/locale/fallbacks.rb".freeze, "lib/i18n/locale/tag.rb".freeze, "lib/i18n/locale/tag/parents.rb".freeze, "lib/i18n/locale/tag/rfc4646.rb".freeze, "lib/i18n/locale/tag/simple.rb".freeze, "lib/i18n/middleware.rb".freeze, "lib/i18n/tests.rb".freeze, "lib/i18n/tests/basics.rb".freeze, "lib/i18n/tests/defaults.rb".freeze, "lib/i18n/tests/interpolation.rb".freeze, "lib/i18n/tests/link.rb".freeze, "lib/i18n/tests/localization.rb".freeze, "lib/i18n/tests/localization/date.rb".freeze, "lib/i18n/tests/localization/date_time.rb".freeze, "lib/i18n/tests/localization/procs.rb".freeze, "lib/i18n/tests/localization/time.rb".freeze, "lib/i18n/tests/lookup.rb".freeze, "lib/i18n/tests/pluralization.rb".freeze, "lib/i18n/tests/procs.rb".freeze, "lib/i18n/version.rb".freeze]
  s.homepage = "http://github.com/ruby-i18n/i18n".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "\nHEADS UP! i18n 1.1 changed fallbacks to exclude default locale.\nBut that may break your application.\n\nPlease check your Rails app for 'config.i18n.fallbacks = true'.\nIf you're using I18n (>= 1.1.0) and Rails (< 5.2.2), this should be\n'config.i18n.fallbacks = [I18n.default_locale]'.\nIf not, fallbacks will be broken in your app by I18n 1.1.x.\n\nFor more info see:\nhttps://github.com/svenfuchs/i18n/releases/tag/v1.1.0\n\n".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "2.7.6".freeze
  s.summary = "New wave Internationalization support for Ruby".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0"])
    else
      s.add_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0"])
    end
  else
    s.add_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0"])
  end
end

