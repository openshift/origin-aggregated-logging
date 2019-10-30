require 'fluent/match'

class Fluent::Plugin::SplunkHecOutput::MatchFormatter
  def initialize(pattern, formatter)
    # based on fluentd/lib/fluent/event_router.rb
    patterns = pattern.split(/\s+/).map { |str|
      Fluent::MatchPattern.create(str)
    }
    @pattern =
      if patterns.length == 1
        patterns[0]
      else
        Fluent::OrMatchPattern.new(patterns)
      end
    @formatter = formatter
  end

  def match?(tag)
    @pattern.match tag
  end

  def format(tag, time, record)
    @formatter.format tag, time, record
  end
end
