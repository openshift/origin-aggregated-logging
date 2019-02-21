# coding: utf-8
require 'fluent/test'
require 'fluent/test/driver/filter'
require 'fluent/plugin/filter_record_modifier'
require 'test/unit'

class RecordModifierFilterTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    @tag = 'test.tag'
  end

  CONFIG = %q!
    remove_keys hoge

    <record>
      gen_host "#{Socket.gethostname}"
      foo bar
      included_tag ${tag}
      tag_wrap -${tag_parts[0]}-${tag_parts[1]}-
    </record>
  !

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::RecordModifierFilter).configure(conf)
  end

  def get_hostname
    require 'socket'
    Socket.gethostname.chomp
  end

  def test_configure
    d = create_driver
    map = d.instance.instance_variable_get(:@map)

    map.each_pair { |k, v|
      assert v.is_a?(Fluent::Plugin::RecordModifierFilter::DynamicExpander)
    }
  end

  def test_format
    d = create_driver

    d.run(default_tag: @tag) do
      d.feed("a" => 1)
      d.feed("a" => 2)
    end

    mapped = {'gen_host' => get_hostname, 'foo' => 'bar', 'included_tag' => @tag, 'tag_wrap' => "-#{@tag.split('.')[0]}-#{@tag.split('.')[1]}-"}
    assert_equal [
      {"a" => 1}.merge(mapped),
      {"a" => 2}.merge(mapped),
    ], d.filtered.map { |e| e.last }
  end

  def test_set_char_encoding
    d = create_driver %[
      char_encoding utf-8
    ]

    d.run(default_tag: @tag) do
      d.feed("k" => 'v'.force_encoding('BINARY'))
      d.feed("k" => %w(v ビ).map{|v| v.force_encoding('BINARY')})
      d.feed("k" => {"l" => 'ビ'.force_encoding('BINARY')})
    end

    assert_equal [
      {"k" => 'v'.force_encoding('UTF-8')},
      {"k" => %w(v ビ).map{|v| v.force_encoding('UTF-8')}},
      {"k" => {"l" => 'ビ'.force_encoding('UTF-8')}},
    ], d.filtered.map { |e| e.last }
  end

  def test_convert_char_encoding
    d = create_driver %[
      char_encoding utf-8:cp932
    ]

    d.run(default_tag: @tag) do
      d.feed("k" => 'v'.force_encoding('utf-8'))
      d.feed("k" => %w(v ビ).map{|v| v.force_encoding('utf-8')})
      d.feed("k" => {"l" => 'ビ'.force_encoding('utf-8')})
    end

    assert_equal [
      {"k" => 'v'.force_encoding('cp932')},
      {"k" => %w(v ビ).map{|v| v.encode!('cp932')}},
      {"k" => {"l" => 'ビ'.encode!('cp932')}},
    ], d.filtered.map { |e| e.last }
  end

  def test_remove_one_key
    d = create_driver %[
      remove_keys k1
    ]

    d.run(default_tag: @tag) do
      d.feed("k1" => 'v', "k2" => 'v')
    end

    assert_equal [{"k2" => 'v'}], d.filtered.map { |e| e.last }
  end

  def test_remove_multiple_keys
    d = create_driver %[
      remove_keys k1, k2, k3
    ]

    d.run(default_tag: @tag) do
      d.feed({"k1" => 'v', "k2" => 'v', "k4" => 'v'})
    end

    assert_equal [{"k4" => 'v'}], d.filtered.map { |e| e.last }
  end

  def test_remove_non_whitelist_keys
    d = create_driver %[
      whitelist_keys k1, k2, k3
    ]

    d.run(default_tag: @tag) do
      d.feed("k1" => 'v', "k2" => 'v', "k4" => 'v', "k5" => 'v')
    end

    assert_equal [{"k1" => 'v', "k2" => 'v'}], d.filtered.map(&:last)
  end

  def test_prepare_values
    d = create_driver %[
      prepare_value @foo = 'foo'
      <record>
        test_key ${@foo}
      </record>
    ]

    d.run(default_tag: @tag) do
      d.feed("k1" => 'v')
    end

    assert_equal [{"k1" => 'v', "test_key" => 'foo'}], d.filtered.map(&:last)
  end

  def test_replace_values
    d = create_driver %[
        <replace>
          key k1
          expression /^(?<start>.+).{2}(?<end>.+)$/
          replace \\k<start>ors\\k<end>
        </replace>
        <replace>
          key k2
          expression /^(.{1}).{2}(.{1})$/
          replace \\1ors\\2
        </replace>
    ]

    d.run(default_tag: @tag) do
      d.feed("k1" => 'hoge', "k2" => 'hoge', "k3" => 'bar')
    end

    assert_equal [{"k1" => 'horse', "k2" => 'horse', "k3" => 'bar'}], d.filtered.map(&:last)
  end

  def test_does_not_replace
    d = create_driver %[
        <replace>
          key k1
          expression /^(?<start>.+).{2}(?<end>.+)$/
          replace \\k<start>ors\\k<end>
        </replace>
    ]

    d.run(default_tag: @tag) do
      d.feed("k1" => 'hog')
    end

    assert_equal [{"k1" => 'hog'}], d.filtered.map(&:last)
  end

  sub_test_case 'frozen check' do
    def test_set_char_encoding
      d = create_driver %[
        char_encoding utf-8
      ]

      d.run(default_tag: @tag) do
        d.feed("k" => 'v'.force_encoding('BINARY').freeze, 'n' => 1)
        d.feed("k" => {"l" => 'v'.force_encoding('BINARY').freeze, 'n' => 1})
      end

      assert_equal [
        {"k" => 'v'.force_encoding('UTF-8'), 'n' => 1},
        {"k" => {"l" => 'v'.force_encoding('UTF-8'), 'n' => 1}},
      ], d.filtered.map { |e| e.last }
    end

    def test_convert_char_encoding
      d = create_driver %[
        char_encoding utf-8:cp932
      ]

      d.run(default_tag: @tag) do
        d.feed("k" => 'v'.force_encoding('utf-8').freeze, 'n' => 1)
        d.feed("k" => {"l" => 'v'.force_encoding('utf-8').freeze, 'n' => 1})
      end

      assert_equal [
        {"k" => 'v'.force_encoding('cp932'), 'n' => 1},
        {"k" => {"l" => 'v'.force_encoding('cp932'), 'n' => 1}},
      ], d.filtered.map { |e| e.last }
    end
  end
end
