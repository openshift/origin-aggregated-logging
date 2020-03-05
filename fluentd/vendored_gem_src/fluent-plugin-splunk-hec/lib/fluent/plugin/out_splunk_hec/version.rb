# frozen_string_literal: true

Fluent::Plugin::SplunkHecOutput::VERSION = File.read(
  File.expand_path('../../../../VERSION', File.dirname(__FILE__))
).chomp.strip
