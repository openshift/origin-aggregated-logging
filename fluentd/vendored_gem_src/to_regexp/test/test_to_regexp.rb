# encoding: UTF-8
require 'helper'

class TestToRegexp < Test::Unit::TestCase
  def test_000_versus_eval_ascii
    str = "/finalis(e)/im"
    old_way = eval(str)
    new_way = str.to_regexp
    assert_equal old_way, new_way
  end

  def test_000a_versus_eval_utf8
    str = "/finalis(é)/im"
    old_way = eval(str)
    new_way = str.to_regexp
    assert_equal old_way, new_way
  end
  
  def test_001_utf8
    assert_equal 'ë', '/(ë)/'.to_regexp.match('Citroën').captures[0]
  end
  
  def test_002_multiline
    assert_equal nil, '/foo.*(bar)/'.to_regexp.match("foo\n\nbar")
    assert_equal 'bar', '/foo.*(bar)/m'.to_regexp.match("foo\n\nbar").captures[0]
  end
  
  def test_003_ignore_case
    assert_equal nil, '/(FOO)/'.to_regexp.match('foo')
    assert_equal 'foo', '/(FOO)/i'.to_regexp.match('foo').captures[0]
  end
  
  def test_004_percentage_r_notation
    assert_equal '/', '%r{(/)}'.to_regexp.match('/').captures[0]
  end
  
  def test_005_multiline_and_ignore_case
    assert_equal 'bar', '/FOO.*(BAR)/mi'.to_regexp.match("foo\n\nbar").captures[0]
  end
  
  def test_006_cant_fix_garbled_input
    if RUBY_VERSION >= '1.9'
      garbled = 'finalisé'.force_encoding('ASCII-8BIT') # like if it was misinterpreted
      assert_raises(Encoding::CompatibilityError) do
        '/finalis(é)/'.to_regexp.match(garbled)
      end
    else # not applicable to ruby 1.8
      garbled = 'finalisé'
      assert_nothing_raised do
        '/finalis(é)/'.to_regexp.match(garbled)
      end
    end
  end
  
  def test_007_possible_garbled_input_fix_using_manfreds_gem
    if RUBY_VERSION >= '1.9'
      require 'ensure/encoding'
      garbled = 'finalisé'.force_encoding('ASCII-8BIT') # like if it was misinterpreted
      assert_equal 'é', '/finalis(é)/'.to_regexp.match(garbled.ensure_encoding('UTF-8')).captures[0]
    else # not applicable to ruby 1.8
      garbled = 'finalisé'
      assert_equal 'é', '/finalis(é)/'.to_regexp.match(garbled).captures[0]
    end
  end
  
  def test_008_as_regexp
    str = '/finalis(é)/in'
    assert_equal ['finalis(é)', ::Regexp::IGNORECASE, 'n'], str.as_regexp
    assert_equal Regexp.new(*str.as_regexp), str.to_regexp
  end
  
  def test_009_ruby_19_splat
    assert_equal nil, 'hi'.to_regexp
  end
  
  def test_010_regexp_to_regexp
    a = /foo/
    assert_equal a, a.to_regexp
  end
  
  def test_011_ignore_case_option
    assert_equal nil, '/(FOO)/'.to_regexp(:ignore_case => false).match('foo')
    assert_equal nil, '/(FOO)/'.to_regexp(:ignore_case => false).match('foo')
    assert_equal 'foo', '/(FOO)/'.to_regexp(:ignore_case => true).match('foo').captures[0]
    assert_equal 'foo', '/(FOO)/i'.to_regexp(:ignore_case => true).match('foo').captures[0]
  end
  
  def test_012_literal_option
    assert '/(FOO)/'.to_regexp(:literal => true).match('hello/(FOO)/there')
  end
  
  def test_013_combine_literal_and_ignore_case
    assert '/(FOO)/'.to_regexp(:literal => true, :ignore_case => true).match('hello/(foo)/there')

    # can't use inline options obviously
    assert_equal nil, '/(FOO)/i'.to_regexp(:literal => true).match('hello/(foo)/there')
    assert '/(FOO)/i'.to_regexp(:literal => true).match('hello/(FOO)/ithere')
  end
  
  def test_014_try_convert
    if RUBY_VERSION >= '1.9'
      assert_equal /foo/i, Regexp.try_convert('/foo/i')
      assert_equal //, Regexp.try_convert('//')
    end
  end
  
  # seen in the wild - from rack-1.2.5/lib/rack/utils.rb - converted to array to preserve order in 1.8.7
  ESCAPE_HTML_KEYS = [
    "&",
    "<",
    ">",
    "'",
    '"',
    "/"
  ]
  def test_015_union
    assert_equal /penzance/, Regexp.union('penzance')
    assert_equal /skiing|sledding/, Regexp.union('skiing', 'sledding')
    assert_equal /skiing|sledding/, Regexp.union(['skiing', 'sledding'])
    assert_equal /(?-mix:dogs)|(?i-mx:cats)/, Regexp.union(/dogs/, /cats/i)
    assert_equal /(?-mix:dogs)|(?i-mx:cats)/, Regexp.union('/dogs/', /cats/i)
    assert_equal /(?-mix:dogs)|(?i-mx:cats)/, Regexp.union(/dogs/, '/cats/i')
    assert_equal %r{&|<|>|'|"|\/}.inspect, Regexp.union(*ESCAPE_HTML_KEYS).inspect
  end

  def test_016_detect
    assert_equal nil, ''.to_regexp(detect: true)
    assert_equal //, '//'.to_regexp(detect: true)
    assert_equal /foo/, 'foo'.to_regexp(detect: true)
    assert_equal %r{foo\\b}, 'foo\b'.to_regexp(detect: true)
    assert_equal %r{foo\b}, '/foo\b/'.to_regexp(detect: true)
    assert_equal %r{foo\\b/}, 'foo\b/'.to_regexp(detect: true)
    assert_equal %r{foo\b}i, '/foo\b/i'.to_regexp(detect: true)
    assert_equal %r{foo\\b/i}, 'foo\b/i'.to_regexp(detect: true)
    assert_equal /FOO.*(BAR)/mi, '/FOO.*(BAR)/mi'.to_regexp(detect: true)
  end

  # https://github.com/ruby/ruby/blob/trunk/test/ruby/test_regexp.rb#L474 "test_union2"
  def test_mri_union2
    assert_equal(/(?!)/, Regexp.union)
    assert_equal(/foo/, Regexp.union(/foo/))
    assert_equal(/foo/, Regexp.union([/foo/]))
    assert_equal(/\t/, Regexp.union("\t"))
    assert_equal(/(?-mix:\u3042)|(?-mix:\u3042)/, Regexp.union(/\u3042/, /\u3042/))
    assert_equal("\u3041", "\u3041"[Regexp.union(/\u3042/, "\u3041")])
  end

  # https://github.com/ruby/ruby/blob/trunk/test/ruby/test_regexp.rb#L464 "test_try_convert"
  def test_mri_try_convert
    assert_equal(/re/, Regexp.try_convert(/re/))
    assert_nil(Regexp.try_convert("re"))

    o = Object.new
    assert_nil(Regexp.try_convert(o))
    def o.to_regexp() /foo/ end
    assert_equal(/foo/, Regexp.try_convert(o))
  end

  # https://github.com/jruby/jruby/blob/master/spec/ruby/core/regexp/try_convert_spec.rb#L5
  def test_jruby_returns_argument_if_given_regexp
    assert_equal /foo/s, Regexp.try_convert(/foo/s)
  end

  # https://github.com/jruby/jruby/blob/master/spec/ruby/core/regexp/try_convert_spec.rb#L9
  def test_jruby_returns_nil_if_given_arg_cant_be_converted
    ['', 'glark', [], Object.new, :pat].each do |arg|
      assert_equal nil, Regexp.try_convert(arg)
    end
  end

  # https://github.com/jruby/jruby/blob/master/test/externals/ruby1.9/uri/test_common.rb#L32
  def test_jruby_uri_common_regexp
    assert_instance_of Regexp, URI.regexp
    assert_instance_of Regexp, URI.regexp(['http'])
    assert_equal URI.regexp, URI.regexp
    assert_equal 'http://', 'x http:// x'.slice(URI.regexp)
    assert_equal 'http://', 'x http:// x'.slice(URI.regexp(['http']))
    assert_equal 'http://', 'x http:// x ftp://'.slice(URI.regexp(['http']))
    assert_equal nil, 'http://'.slice(URI.regexp([]))
    assert_equal nil, ''.slice(URI.regexp)
    assert_equal nil, 'xxxx'.slice(URI.regexp)
    assert_equal nil, ':'.slice(URI.regexp)
    assert_equal 'From:', 'From:'.slice(URI.regexp)
  end

  # https://github.com/jruby/jruby/blob/master/spec/ruby/core/regexp/union_spec.rb#L14
  def test_jruby_quotes_string_arguments
    assert_equal /n|\./, Regexp.union("n", ".")
  end

end
