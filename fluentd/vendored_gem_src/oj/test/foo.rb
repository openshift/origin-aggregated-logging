#!/usr/bin/env ruby

$: << '.'
$: << File.join(File.dirname(__FILE__), "../lib")
$: << File.join(File.dirname(__FILE__), "../ext")

# require 'json'
require 'oj'
Oj.mimic_JSON

source = %( {"a": 1, "b": 2} )
puts "JSON.load, no symbolize => OK"
pp JSON.load( source )
puts "JSON.load, do symbolize => KO: keys are not symbols"
#pp JSON.load( source, nil, symbolize_names: true, create_additions: false )
pp JSON.load( source, nil, symbolize_names: true, create_additions: false )
puts "JSON.parse, no symbolize => OK"
pp JSON.parse( source )
puts "JSON.parse, do symbolize => OK"
pp JSON.parse( source, symbolize_names: true )
