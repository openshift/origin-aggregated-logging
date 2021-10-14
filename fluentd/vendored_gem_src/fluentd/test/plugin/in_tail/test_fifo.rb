require_relative '../../helper'

require 'fluent/plugin/in_tail'

class IntailFIFO < Test::Unit::TestCase
  sub_test_case '#read_line' do
    test 'returns lines spliting per `\n`' do
      fifo = Fluent::Plugin::TailInput::TailWatcher::FIFO.new(Encoding::ASCII_8BIT, Encoding::ASCII_8BIT)
      text = ("test\n" * 3).force_encoding(Encoding::ASCII_8BIT)
      fifo << text
      lines = []
      fifo.read_lines(lines)
      assert_equal Encoding::ASCII_8BIT, lines[0].encoding
      assert_equal ["test\n", "test\n", "test\n"], lines
    end

    test 'concant line when line is separated' do
      fifo = Fluent::Plugin::TailInput::TailWatcher::FIFO.new(Encoding::ASCII_8BIT, Encoding::ASCII_8BIT)
      text = ("test\n" * 3 + 'test').force_encoding(Encoding::ASCII_8BIT)
      fifo << text
      lines = []
      fifo.read_lines(lines)
      assert_equal Encoding::ASCII_8BIT, lines[0].encoding
      assert_equal ["test\n", "test\n", "test\n"], lines

      fifo << "2\n"
      fifo.read_lines(lines)
      assert_equal Encoding::ASCII_8BIT, lines[0].encoding
      assert_equal ["test\n", "test\n", "test\n", "test2\n"], lines
    end

    test 'returns lines which convert encoding' do
      fifo = Fluent::Plugin::TailInput::TailWatcher::FIFO.new(Encoding::ASCII_8BIT, Encoding::UTF_8)
      text = ("test\n" * 3).force_encoding(Encoding::ASCII_8BIT)
      fifo << text
      lines = []
      fifo.read_lines(lines)
      assert_equal Encoding::UTF_8, lines[0].encoding
      assert_equal ["test\n", "test\n", "test\n"], lines
    end

    test 'reads lines as from_encoding' do
      fifo = Fluent::Plugin::TailInput::TailWatcher::FIFO.new(Encoding::UTF_8, Encoding::ASCII_8BIT)
      text = ("test\n" * 3).force_encoding(Encoding::UTF_8)
      fifo << text
      lines = []
      fifo.read_lines(lines)
      assert_equal Encoding::ASCII_8BIT, lines[0].encoding
      assert_equal ["test\n", "test\n", "test\n"], lines
    end

    sub_test_case 'when it includes multi byte chars' do
      test 'handles it as ascii_8bit' do
        fifo = Fluent::Plugin::TailInput::TailWatcher::FIFO.new(Encoding::ASCII_8BIT, Encoding::ASCII_8BIT)
        text = ("てすと\n" * 3).force_encoding(Encoding::ASCII_8BIT)
        fifo << text
        lines = []
        fifo.read_lines(lines)
        assert_equal Encoding::ASCII_8BIT, lines[0].encoding
        assert_equal ["てすと\n", "てすと\n", "てすと\n"].map { |e| e.force_encoding(Encoding::ASCII_8BIT) }, lines
      end

      test 'replaces character with ? when convert error happens' do
        fifo = Fluent::Plugin::TailInput::TailWatcher::FIFO.new(Encoding::UTF_8, Encoding::ASCII_8BIT)
        text = ("てすと\n" * 3).force_encoding(Encoding::UTF_8)
        fifo << text
        lines = []
        fifo.read_lines(lines)
        assert_equal Encoding::ASCII_8BIT, lines[0].encoding
        assert_equal ["???\n", "???\n", "???\n"].map { |e| e.force_encoding(Encoding::ASCII_8BIT) }, lines
      end
    end

    test 'reutrns nothing when buffer is empty' do
      fifo = Fluent::Plugin::TailInput::TailWatcher::FIFO.new(Encoding::ASCII_8BIT, Encoding::ASCII_8BIT)
      lines = []
      fifo.read_lines(lines)
      assert_equal [], lines

      text = "test\n" * 3
      fifo << text
      fifo.read_lines(lines)
      assert_equal ["test\n", "test\n", "test\n"], lines

      lines = []
      fifo.read_lines(lines)
      assert_equal [], lines
    end
  end

  sub_test_case '#<<' do
    test 'does not make any change about encoding to an argument' do
      fifo = Fluent::Plugin::TailInput::TailWatcher::FIFO.new(Encoding::ASCII_8BIT, Encoding::ASCII_8BIT)
      text = ("test\n" * 3).force_encoding(Encoding::UTF_8)

      assert_equal Encoding::UTF_8, text.encoding
      fifo << text
      assert_equal Encoding::UTF_8, text.encoding
    end
  end

  sub_test_case '#bytesize' do
    test 'reutrns buffer size' do
      fifo = Fluent::Plugin::TailInput::TailWatcher::FIFO.new(Encoding::ASCII_8BIT, Encoding::ASCII_8BIT)
      text = "test\n" * 3 + 'test'
      fifo << text

      assert_equal text.bytesize, fifo.bytesize
      lines = []
      fifo.read_lines(lines)
      assert_equal ["test\n", "test\n", "test\n"], lines

      assert_equal 'test'.bytesize, fifo.bytesize
      fifo << "2\n"
      fifo.read_lines(lines)
      assert_equal ["test\n", "test\n", "test\n", "test2\n"], lines

      assert_equal 0, fifo.bytesize
    end
  end
end
