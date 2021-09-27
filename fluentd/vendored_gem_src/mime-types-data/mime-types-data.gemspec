# -*- encoding: utf-8 -*-
# stub: mime-types-data 3.2021.0901 ruby lib

Gem::Specification.new do |s|
  s.name = "mime-types-data".freeze
  s.version = "3.2021.0901"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Austin Ziegler".freeze]
  s.date = "2021-09-02"
  s.description = "mime-types-data provides a registry for information about MIME media type\ndefinitions. It can be used with the Ruby mime-types library or other software\nto determine defined filename extensions for MIME types, or to use filename\nextensions to look up the likely MIME type definitions.".freeze
  s.email = ["halostatue@gmail.com".freeze]
  s.extra_rdoc_files = ["Code-of-Conduct.md".freeze, "Contributing.md".freeze, "History.md".freeze, "Licence.md".freeze, "Manifest.txt".freeze, "README.md".freeze]
  s.files = ["Code-of-Conduct.md".freeze, "Contributing.md".freeze, "History.md".freeze, "Licence.md".freeze, "Manifest.txt".freeze, "README.md".freeze, "Rakefile".freeze, "data/mime-types.json".freeze, "data/mime.content_type.column".freeze, "data/mime.docs.column".freeze, "data/mime.encoding.column".freeze, "data/mime.flags.column".freeze, "data/mime.friendly.column".freeze, "data/mime.pext.column".freeze, "data/mime.use_instead.column".freeze, "data/mime.xrefs.column".freeze, "lib/mime-types-data.rb".freeze, "lib/mime/types/data.rb".freeze, "types/application.yaml".freeze, "types/audio.yaml".freeze, "types/chemical.yaml".freeze, "types/conference.yaml".freeze, "types/drawing.yaml".freeze, "types/font.yaml".freeze, "types/image.yaml".freeze, "types/message.yaml".freeze, "types/model.yaml".freeze, "types/multipart.yaml".freeze, "types/text.yaml".freeze, "types/video.yaml".freeze, "types/world.yaml".freeze]
  s.homepage = "https://github.com/mime-types/mime-types-data/".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubygems_version = "3.0.9".freeze
  s.summary = "mime-types-data provides a registry for information about MIME media type definitions".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<nokogiri>.freeze, ["~> 1.6"])
      s.add_development_dependency(%q<hoe-doofus>.freeze, ["~> 1.0"])
      s.add_development_dependency(%q<hoe-gemspec2>.freeze, ["~> 1.1"])
      s.add_development_dependency(%q<hoe-git>.freeze, ["~> 1.6"])
      s.add_development_dependency(%q<hoe-rubygems>.freeze, ["~> 1.0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 10.0", "< 14"])
      s.add_development_dependency(%q<mime-types>.freeze, [">= 3.2.1", "< 4"])
      s.add_development_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 3.23"])
    else
      s.add_dependency(%q<nokogiri>.freeze, ["~> 1.6"])
      s.add_dependency(%q<hoe-doofus>.freeze, ["~> 1.0"])
      s.add_dependency(%q<hoe-gemspec2>.freeze, ["~> 1.1"])
      s.add_dependency(%q<hoe-git>.freeze, ["~> 1.6"])
      s.add_dependency(%q<hoe-rubygems>.freeze, ["~> 1.0"])
      s.add_dependency(%q<rake>.freeze, [">= 10.0", "< 14"])
      s.add_dependency(%q<mime-types>.freeze, [">= 3.2.1", "< 4"])
      s.add_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
      s.add_dependency(%q<hoe>.freeze, ["~> 3.23"])
    end
  else
    s.add_dependency(%q<nokogiri>.freeze, ["~> 1.6"])
    s.add_dependency(%q<hoe-doofus>.freeze, ["~> 1.0"])
    s.add_dependency(%q<hoe-gemspec2>.freeze, ["~> 1.1"])
    s.add_dependency(%q<hoe-git>.freeze, ["~> 1.6"])
    s.add_dependency(%q<hoe-rubygems>.freeze, ["~> 1.0"])
    s.add_dependency(%q<rake>.freeze, [">= 10.0", "< 14"])
    s.add_dependency(%q<mime-types>.freeze, [">= 3.2.1", "< 4"])
    s.add_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.23"])
  end
end

