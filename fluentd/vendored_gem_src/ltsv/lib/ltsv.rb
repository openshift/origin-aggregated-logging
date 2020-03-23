# = ltsv - A parser / dumper for Labelled Tab-Separated Values(LTSV)
#
# Copyright (C) 2013 TOYODA Naoto.
#
#
module LTSV
  VERSION = "0.1.2"

  # Parsing given stream or string.
  # If you specified a stream as the first argument,
  # this method behaves as same as #load.
  #
  # == Arguments:
  # * _io_or_string_: a target to parse. Possible values are: String, IO.  
  #   If you give the string value, it stands the content to parse.  
  #   If you give the IO value, it stands the stream which provides the contents to parse.
  # == Options:
  # * _symbolize_keys_ : Whether the label will be available as symbol or not.  
  #   Default value is true.
  # * _encoding_ : The encoding of the stream given as the first argument.  
  #   It is effective only when the first argument is an instance of IO.  
  #   Default value: Encoding.default_external
  # == Returns:
  # * An instance of Hash : When you give the string as the first argument.
  # * An Array of Hash : When you give the IO as the first argument.
  def parse(io_or_string, options = {})
    case io_or_string
    when String
      parse_string(io_or_string, options)
    when IO
      parse_io(io_or_string, options)
    end
  end

  # Parsing the content of the given stream or path.
  # If you specified a stream as the first argument,
  # this method behaves as same as #load.
  #
  # == Arguments:
  # * _io_or_string_: a target to parse. Possible values are: String, IO.  
  #   If you give the string value, it stands the path of the file to parse.  
  #   If you give the IO value, it stands the stream which provides the contents to parse.  
  #   *Note* : If you give the IO value, this method behaves like #parse.
  # == Options:
  # * _symbolize_keys_ : Whether the label will be available as symbol or not.  
  #   Default value is true.
  # * _encoding_ : The encoding of the stream given as the first argument.  
  #   Default value: Encoding.default_external
  # == Returns:
  # * An Array of Hash : Each hash stands for a line of the io or the file.
  def load(io_or_string, options = {})
    encoding_opt = options.delete :encoding
    encoding =
      encoding_opt ? Encoding.find(encoding_opt) : Encoding.default_external

    case io_or_string
    when String
      File.open(io_or_string, "r:#{encoding}"){|f|parse_io(f, options)}
    when IO
      parse_io(io_or_string, options)
    end
  end

  # Dumping the value given into a new String.
  # Each special character will be escaped with backslash('\'), and the expression should be contained in a single line.
  #
  # == Arguments:
  # * _value_: a target to dump. It should respond to :to_hash.
  # == Returns:
  # * A LTSV String
  def dump(value)
    raise ArgumentError, "dump should take an argument of hash" unless
      value.respond_to? :to_hash

    hash = value.to_hash

    hash.inject('') do |s, kv|
      s << "\t" if s.bytesize > 0

      (k, v) = kv
      value = escape v
      s << k.to_s << ':' << value
    end
  end

  def parse_line(line, options={})#:nodoc:
    symbolize_keys = options.delete(:symbolize_keys)
    symbolize_keys = true if symbolize_keys.nil?

    line.split("\t").inject({}) do |h, i|
      (key, value) = i.split(':', 2)
      next unless key
      key = key.to_sym if symbolize_keys
      unescape!(value)
      h[key] = case value
           when nil then nil
           when '' then nil
           else value
           end
      h
    end
  end

  private

  def parse_io(io, options)#:nodoc:
    io.map{|l|parse_line l.chomp, options}
  end

  def parse_string(string, options)#:nodoc:
    string.chomp.split($/).map{|l|parse_line l, options}
  end

  def unescape!(string)#:nodoc:
    return nil if !string || string == ''

    string.gsub!(/\\([a-z\\])/) do |m|
      case $1
      when 'r'
        "\r"
      when 'n'
        "\n"
      when 't'
        "\t"
      when '\\'
        '\\'
      else
        m
      end
    end
  end

  def escape(string)#:nodoc:
    value = string.kind_of?(String) ? string.dup : string.to_s

    value
      .gsub("\\", "\\\\")
      .gsub("\n", "\\n")
      .gsub("\r", "\\r")
      .gsub("\t", "\\t")
  end

  module_function :load, :parse, :dump, :parse_io, :parse_string, :parse_line, :unescape!, :escape

  class <<self
    private :parse_io, :parse_string, :unescape!, :escape
  end
end
