#!/usr/bin/env ruby

require 'oj'

Oj::default_options = {cache_str: 0, cache_keys: true, mode: :strict}

puts "Ruby version: #{RUBY_VERSION}"
puts "Oj version: #{Oj::VERSION}"

puts "cache_keys: #{Oj::default_options[:cache_keys]}"
puts "cache_str: #{Oj::default_options[:cache_str]}"

Oj.load('{"":""}').each_pair {|k,v| puts "k.frozen?: #{k.frozen?}\nv.frozen?: #{v.frozen?}"}
