# -*- encoding: utf-8 -*-
# stub: mail 2.7.1 ruby lib

Gem::Specification.new do |s|
  s.name = "mail".freeze
  s.version = "2.7.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mikel Lindsaar".freeze]
  s.date = "2018-10-13"
  s.description = "A really Ruby Mail handler.".freeze
  s.email = "raasdnil@gmail.com".freeze
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["MIT-LICENSE".freeze, "README.md".freeze, "lib/mail.rb".freeze, "lib/mail/attachments_list.rb".freeze, "lib/mail/body.rb".freeze, "lib/mail/check_delivery_params.rb".freeze, "lib/mail/configuration.rb".freeze, "lib/mail/constants.rb".freeze, "lib/mail/core_extensions/smtp.rb".freeze, "lib/mail/core_extensions/string.rb".freeze, "lib/mail/elements.rb".freeze, "lib/mail/elements/address.rb".freeze, "lib/mail/elements/address_list.rb".freeze, "lib/mail/elements/content_disposition_element.rb".freeze, "lib/mail/elements/content_location_element.rb".freeze, "lib/mail/elements/content_transfer_encoding_element.rb".freeze, "lib/mail/elements/content_type_element.rb".freeze, "lib/mail/elements/date_time_element.rb".freeze, "lib/mail/elements/envelope_from_element.rb".freeze, "lib/mail/elements/message_ids_element.rb".freeze, "lib/mail/elements/mime_version_element.rb".freeze, "lib/mail/elements/phrase_list.rb".freeze, "lib/mail/elements/received_element.rb".freeze, "lib/mail/encodings.rb".freeze, "lib/mail/encodings/7bit.rb".freeze, "lib/mail/encodings/8bit.rb".freeze, "lib/mail/encodings/base64.rb".freeze, "lib/mail/encodings/binary.rb".freeze, "lib/mail/encodings/identity.rb".freeze, "lib/mail/encodings/quoted_printable.rb".freeze, "lib/mail/encodings/transfer_encoding.rb".freeze, "lib/mail/encodings/unix_to_unix.rb".freeze, "lib/mail/envelope.rb".freeze, "lib/mail/field.rb".freeze, "lib/mail/field_list.rb".freeze, "lib/mail/fields.rb".freeze, "lib/mail/fields/bcc_field.rb".freeze, "lib/mail/fields/cc_field.rb".freeze, "lib/mail/fields/comments_field.rb".freeze, "lib/mail/fields/common/address_container.rb".freeze, "lib/mail/fields/common/common_address.rb".freeze, "lib/mail/fields/common/common_date.rb".freeze, "lib/mail/fields/common/common_field.rb".freeze, "lib/mail/fields/common/common_message_id.rb".freeze, "lib/mail/fields/common/parameter_hash.rb".freeze, "lib/mail/fields/content_description_field.rb".freeze, "lib/mail/fields/content_disposition_field.rb".freeze, "lib/mail/fields/content_id_field.rb".freeze, "lib/mail/fields/content_location_field.rb".freeze, "lib/mail/fields/content_transfer_encoding_field.rb".freeze, "lib/mail/fields/content_type_field.rb".freeze, "lib/mail/fields/date_field.rb".freeze, "lib/mail/fields/from_field.rb".freeze, "lib/mail/fields/in_reply_to_field.rb".freeze, "lib/mail/fields/keywords_field.rb".freeze, "lib/mail/fields/message_id_field.rb".freeze, "lib/mail/fields/mime_version_field.rb".freeze, "lib/mail/fields/optional_field.rb".freeze, "lib/mail/fields/received_field.rb".freeze, "lib/mail/fields/references_field.rb".freeze, "lib/mail/fields/reply_to_field.rb".freeze, "lib/mail/fields/resent_bcc_field.rb".freeze, "lib/mail/fields/resent_cc_field.rb".freeze, "lib/mail/fields/resent_date_field.rb".freeze, "lib/mail/fields/resent_from_field.rb".freeze, "lib/mail/fields/resent_message_id_field.rb".freeze, "lib/mail/fields/resent_sender_field.rb".freeze, "lib/mail/fields/resent_to_field.rb".freeze, "lib/mail/fields/return_path_field.rb".freeze, "lib/mail/fields/sender_field.rb".freeze, "lib/mail/fields/structured_field.rb".freeze, "lib/mail/fields/subject_field.rb".freeze, "lib/mail/fields/to_field.rb".freeze, "lib/mail/fields/unstructured_field.rb".freeze, "lib/mail/header.rb".freeze, "lib/mail/indifferent_hash.rb".freeze, "lib/mail/mail.rb".freeze, "lib/mail/matchers/attachment_matchers.rb".freeze, "lib/mail/matchers/has_sent_mail.rb".freeze, "lib/mail/message.rb".freeze, "lib/mail/multibyte.rb".freeze, "lib/mail/multibyte/chars.rb".freeze, "lib/mail/multibyte/unicode.rb".freeze, "lib/mail/multibyte/utils.rb".freeze, "lib/mail/network.rb".freeze, "lib/mail/network/delivery_methods/exim.rb".freeze, "lib/mail/network/delivery_methods/file_delivery.rb".freeze, "lib/mail/network/delivery_methods/logger_delivery.rb".freeze, "lib/mail/network/delivery_methods/sendmail.rb".freeze, "lib/mail/network/delivery_methods/smtp.rb".freeze, "lib/mail/network/delivery_methods/smtp_connection.rb".freeze, "lib/mail/network/delivery_methods/test_mailer.rb".freeze, "lib/mail/network/retriever_methods/base.rb".freeze, "lib/mail/network/retriever_methods/imap.rb".freeze, "lib/mail/network/retriever_methods/pop3.rb".freeze, "lib/mail/network/retriever_methods/test_retriever.rb".freeze, "lib/mail/parser_tools.rb".freeze, "lib/mail/parsers.rb".freeze, "lib/mail/parsers/address_lists_parser.rb".freeze, "lib/mail/parsers/address_lists_parser.rl".freeze, "lib/mail/parsers/content_disposition_parser.rb".freeze, "lib/mail/parsers/content_disposition_parser.rl".freeze, "lib/mail/parsers/content_location_parser.rb".freeze, "lib/mail/parsers/content_location_parser.rl".freeze, "lib/mail/parsers/content_transfer_encoding_parser.rb".freeze, "lib/mail/parsers/content_transfer_encoding_parser.rl".freeze, "lib/mail/parsers/content_type_parser.rb".freeze, "lib/mail/parsers/content_type_parser.rl".freeze, "lib/mail/parsers/date_time_parser.rb".freeze, "lib/mail/parsers/date_time_parser.rl".freeze, "lib/mail/parsers/envelope_from_parser.rb".freeze, "lib/mail/parsers/envelope_from_parser.rl".freeze, "lib/mail/parsers/message_ids_parser.rb".freeze, "lib/mail/parsers/message_ids_parser.rl".freeze, "lib/mail/parsers/mime_version_parser.rb".freeze, "lib/mail/parsers/mime_version_parser.rl".freeze, "lib/mail/parsers/phrase_lists_parser.rb".freeze, "lib/mail/parsers/phrase_lists_parser.rl".freeze, "lib/mail/parsers/received_parser.rb".freeze, "lib/mail/parsers/received_parser.rl".freeze, "lib/mail/parsers/rfc2045_content_transfer_encoding.rl".freeze, "lib/mail/parsers/rfc2045_content_type.rl".freeze, "lib/mail/parsers/rfc2045_mime.rl".freeze, "lib/mail/parsers/rfc2183_content_disposition.rl".freeze, "lib/mail/parsers/rfc3629_utf8.rl".freeze, "lib/mail/parsers/rfc5234_abnf_core_rules.rl".freeze, "lib/mail/parsers/rfc5322.rl".freeze, "lib/mail/parsers/rfc5322_address.rl".freeze, "lib/mail/parsers/rfc5322_date_time.rl".freeze, "lib/mail/parsers/rfc5322_lexical_tokens.rl".freeze, "lib/mail/part.rb".freeze, "lib/mail/parts_list.rb".freeze, "lib/mail/utilities.rb".freeze, "lib/mail/values/unicode_tables.dat".freeze, "lib/mail/version.rb".freeze, "lib/mail/version_specific/ruby_1_8.rb".freeze, "lib/mail/version_specific/ruby_1_9.rb".freeze]
  s.homepage = "https://github.com/mikel/mail".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--exclude".freeze, "lib/mail/values/unicode_tables.dat".freeze]
  s.rubygems_version = "3.0.9".freeze
  s.summary = "Mail provides a nice Ruby DSL for making, sending and reading emails.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mini_mime>.freeze, [">= 0.1.1"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 1.0.3"])
      s.add_development_dependency(%q<rake>.freeze, ["> 0.8.7"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_development_dependency(%q<rdoc>.freeze, [">= 0"])
      s.add_development_dependency(%q<rufo>.freeze, [">= 0"])
    else
      s.add_dependency(%q<mini_mime>.freeze, [">= 0.1.1"])
      s.add_dependency(%q<bundler>.freeze, [">= 1.0.3"])
      s.add_dependency(%q<rake>.freeze, ["> 0.8.7"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_dependency(%q<rdoc>.freeze, [">= 0"])
      s.add_dependency(%q<rufo>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<mini_mime>.freeze, [">= 0.1.1"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.0.3"])
    s.add_dependency(%q<rake>.freeze, ["> 0.8.7"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_dependency(%q<rdoc>.freeze, [">= 0"])
    s.add_dependency(%q<rufo>.freeze, [">= 0"])
  end
end

