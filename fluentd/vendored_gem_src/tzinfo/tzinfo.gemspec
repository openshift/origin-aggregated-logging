# -*- encoding: utf-8 -*-
# stub: tzinfo 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "tzinfo".freeze
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Philip Ross".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDPDCCAiSgAwIBAgIBATANBgkqhkiG9w0BAQsFADAkMSIwIAYDVQQDDBlwaGls\nLnJvc3MvREM9Z21haWwvREM9Y29tMB4XDTE4MTAyNzE3NTQyNVoXDTE5MTAyNzE3\nNTQyNVowJDEiMCAGA1UEAwwZcGhpbC5yb3NzL0RDPWdtYWlsL0RDPWNvbTCCASIw\nDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJGcwfqn4ZsmPl0b1Lt9dCzExrE5\nEeP/CRQjBdGHkF+mSpi69XysxdwLdfg5SPr9LfxthUug4nNFd5fDCiXM8hYe9jQD\nTmkIQKNBh4fFpGngn9gyy+SumCXi6b5L6d/aMc59NAOM6LJ88TOdH1648dh5rq3C\nULq82n3gg4+u0HHGjRPuR/pnCFQCZbANYdX+UBWd0qkOJn/EreNKROmEeHr/xKuh\n2/GlKFKt9KLcW3hwBB4fHHVYUzRau7D1m9KbEERdg//qNDC4B7fD2BFJuPbM5S7J\n41VwDAh1O8B/Qpg0f+S83K4Kodw4MiPGsug55UkNtd3mGR/zZJ9WM03DSwkCAwEA\nAaN5MHcwCQYDVR0TBAIwADALBgNVHQ8EBAMCBLAwHQYDVR0OBBYEFA+Z8zvfzBuA\nesoHIfz7+jxfUOcfMB4GA1UdEQQXMBWBE3BoaWwucm9zc0BnbWFpbC5jb20wHgYD\nVR0SBBcwFYETcGhpbC5yb3NzQGdtYWlsLmNvbTANBgkqhkiG9w0BAQsFAAOCAQEA\nG7spOhX+wjEVvsn5KAqbeDXcRhnuAzz/DbAq8xkG84etG4HNNdGxe8z7DY0YuqQQ\nuau4AXpjQwtXRp6wYrzLjpn6Gsj0NGcv9TOcxHPPpr/cZnFuLdN5Sk7Q1sK8OuJ1\n7JSj/nRsuNVgoo5dSAghVbCUNd2Ch31oDGPQFzedmKo09mNTd72CfcjzrjXaHDIB\nObXSs1zIhlYXDJGC5Dpr1/fG2W7bd8xt4UwQBH8u53KKYbHjHcbF+9x3O9TDweZq\nlDDjxNrOZq4IuD3jrJI+T95Lo5RSCenQmPnJIGtfaoN+omC2q0HMFNx31TcWCcC8\nY2Wt5gQskVrMQo+j0zgJcw==\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2018-12-26"
  s.description = "TZInfo provides access to time zone data and allows times to be converted using time zone rules.".freeze
  s.email = "phil.ross@gmail.com".freeze
  s.extra_rdoc_files = ["README.md".freeze, "CHANGES.md".freeze, "LICENSE".freeze]
  s.files = [".yardopts".freeze, "CHANGES.md".freeze, "LICENSE".freeze, "README.md".freeze, "lib/tzinfo.rb".freeze, "lib/tzinfo/country.rb".freeze, "lib/tzinfo/country_timezone.rb".freeze, "lib/tzinfo/data_source.rb".freeze, "lib/tzinfo/data_sources.rb".freeze, "lib/tzinfo/data_sources/constant_offset_data_timezone_info.rb".freeze, "lib/tzinfo/data_sources/country_info.rb".freeze, "lib/tzinfo/data_sources/data_timezone_info.rb".freeze, "lib/tzinfo/data_sources/linked_timezone_info.rb".freeze, "lib/tzinfo/data_sources/ruby_data_source.rb".freeze, "lib/tzinfo/data_sources/timezone_info.rb".freeze, "lib/tzinfo/data_sources/transitions_data_timezone_info.rb".freeze, "lib/tzinfo/data_sources/zoneinfo_data_source.rb".freeze, "lib/tzinfo/data_sources/zoneinfo_reader.rb".freeze, "lib/tzinfo/data_timezone.rb".freeze, "lib/tzinfo/datetime_with_offset.rb".freeze, "lib/tzinfo/format1.rb".freeze, "lib/tzinfo/format1/country_definer.rb".freeze, "lib/tzinfo/format1/country_index_definition.rb".freeze, "lib/tzinfo/format1/timezone_definer.rb".freeze, "lib/tzinfo/format1/timezone_definition.rb".freeze, "lib/tzinfo/format1/timezone_index_definition.rb".freeze, "lib/tzinfo/format2.rb".freeze, "lib/tzinfo/format2/country_definer.rb".freeze, "lib/tzinfo/format2/country_index_definer.rb".freeze, "lib/tzinfo/format2/country_index_definition.rb".freeze, "lib/tzinfo/format2/timezone_definer.rb".freeze, "lib/tzinfo/format2/timezone_definition.rb".freeze, "lib/tzinfo/format2/timezone_index_definer.rb".freeze, "lib/tzinfo/format2/timezone_index_definition.rb".freeze, "lib/tzinfo/info_timezone.rb".freeze, "lib/tzinfo/linked_timezone.rb".freeze, "lib/tzinfo/offset_timezone_period.rb".freeze, "lib/tzinfo/string_deduper.rb".freeze, "lib/tzinfo/time_with_offset.rb".freeze, "lib/tzinfo/timestamp.rb".freeze, "lib/tzinfo/timestamp_with_offset.rb".freeze, "lib/tzinfo/timezone.rb".freeze, "lib/tzinfo/timezone_offset.rb".freeze, "lib/tzinfo/timezone_period.rb".freeze, "lib/tzinfo/timezone_proxy.rb".freeze, "lib/tzinfo/timezone_transition.rb".freeze, "lib/tzinfo/transitions_timezone_period.rb".freeze, "lib/tzinfo/version.rb".freeze, "lib/tzinfo/with_offset.rb".freeze]
  s.homepage = "https://tzinfo.github.io".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--title".freeze, "TZInfo".freeze, "--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Time Zone Library".freeze

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

