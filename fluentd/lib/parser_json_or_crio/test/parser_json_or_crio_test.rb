require_relative 'test_helper'
require 'fluent/test'
require 'test/unit/rr'
require File.join(File.dirname(__FILE__), '..', 'lib/parser_json_or_crio') 

class JsonOrCrioParserTest < Test::Unit::TestCase
  include Fluent

  def test_json
    parser = Fluent::Test::ParserTestDriver.new(Fluent::ParserJsonOrCrio, nil)
    parser.configure(
      '@type'=>'tail',
      '@id'=>'file-input',
      'path'=>'/tmp/junk',
      'pos_file'=>'/tmp/junk.pos',
      'tag'=>'kubernetes.*',
      'keep_time_key'=>'true',
      'read_from_head'=>'true',
      'exclude_path'=>'[]'
    )
    time, record = parser.parse('{"log":"{\"message\":\"a log record\"}","stream":"stdout","time":"2018-08-22T17:04:12.385850123Z"}')
    assert_equal 1534957452, time
    assert_equal '{"message":"a log record"}', record['log']
    assert_equal "stdout", record['stream']
  end
  def test_json_with_custom_time_format
    parser = Fluent::Test::ParserTestDriver.new(Fluent::ParserJsonOrCrio, nil)
    parser.configure(
      '@type'=>'tail',
      '@id'=>'file-input',
      'path'=>'/tmp/junk',
      'pos_file'=>'/tmp/junk.pos',
      'json_time_format'=>'%Y-%m-%dT%H:%M:%S%:z',
      'tag'=>'kubernetes.*',
      'keep_time_key'=>'true',
      'read_from_head'=>'true',
      'exclude_path'=>'[]'
    )
    time, record = parser.parse('{"log":"{\"message\":\"a log record\"}","stream":"stdout","time":"2018-08-22T17:04:12+00:00"}')
    assert_equal 1534957452, time
    assert_equal '{"message":"a log record"}', record['log']
    assert_equal "stdout", record['stream']
  end
  def test_crio
    parser = Fluent::Test::ParserTestDriver.new(Fluent::ParserJsonOrCrio, nil)
    parser.configure(
      '@type'=>'tail',
      '@id'=>'file-input',
      'path'=>'/tmp/junk',
      'pos_file'=>'/tmp/junk.pos',
      'tag'=>'kubernetes.*',
      'keep_time_key'=>'true',
      'read_from_head'=>'true',
      'exclude_path'=>'[]'
    )
    time, record = parser.parse('2018-08-22T17:04:12.385850+00:00 stdout {"message":"a log record"}')
    assert_equal 1534957452, time
    assert_equal '{"message":"a log record"}', record['log']
    assert_equal "stdout", record['stream']
  end
  def test_crio_with_custom_format
    parser = Fluent::Test::ParserTestDriver.new(Fluent::ParserJsonOrCrio, nil)
    parser.configure(
      '@type'=>'tail',
      '@id'=>'file-input',
      'path'=>'/tmp/junk',
      'pos_file'=>'/tmp/junk.pos',
      'crio_time_format'=>'%Y-%m-%dT%H:%M:%S%Z',
      'tag'=>'kubernetes.*',
      'keep_time_key'=>'true',
      'read_from_head'=>'true',
      'exclude_path'=>'[]',
      'crio_format'=>'/^(?<time>.+) (?<junk>.) (?<log>.*)$/'
    )
    time, record = parser.parse('2018-08-22T17:04:12Z A {"message":"a log record"}')
    assert_equal 1534957452, time
    assert_equal '{"message":"a log record"}', record['log']
    assert_equal "A", record['junk']
  end
  def test_with_bogus_json
    parser = Fluent::Test::ParserTestDriver.new(Fluent::ParserJsonOrCrio, nil)
    parser.configure(
      '@type'=>'tail',
      '@id'=>'file-input',
      'path'=>'/tmp/junk',
      'pos_file'=>'/tmp/junk.pos',
      'tag'=>'kubernetes.*',
      'keep_time_key'=>'true',
      'read_from_head'=>'true',
      'exclude_path'=>'[]'
    )
    time, record = parser.parse('{not valid json}')
    assert_equal nil, time
    assert_equal nil, record
  end
  def test_with_empty_string
    parser = Fluent::Test::ParserTestDriver.new(Fluent::ParserJsonOrCrio, nil)
    parser.configure(
      '@type'=>'tail',
      '@id'=>'file-input',
      'path'=>'/tmp/junk',
      'pos_file'=>'/tmp/junk.pos',
      'tag'=>'kubernetes.*',
      'keep_time_key'=>'true',
      'read_from_head'=>'true',
      'exclude_path'=>'[]'
    )
    time, record = parser.parse('')
    assert_equal nil, time
    assert_equal nil, record
  end
end
