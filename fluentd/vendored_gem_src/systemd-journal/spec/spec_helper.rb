require 'rspec'
require 'json'
require 'simplecov'

module SpecHelper
  def fixture_dir
    @path ||= File.join(File.expand_path('..', __FILE__), 'fixtures')
  end

  def journal_file
    @file ||= File.join(fixture_dir, 'test.journal')
  end

  def journal_json
    @json ||= JSON.parse(File.read(File.join(fixture_dir, 'test.json')))
  end

  def entry_field(index, name)
    journal_json[index][name.to_s.upcase]
  end
end

SimpleCov.start do
  add_filter '.bundle/'
end
require 'systemd/journal'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.include SpecHelper
end
