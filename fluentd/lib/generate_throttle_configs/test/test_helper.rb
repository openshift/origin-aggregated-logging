require File.join(File.dirname(__FILE__), '..', 'lib/generate_throttle_configs') 
require 'minitest/autorun'
require 'fileutils'

def create_test_file(content=nil)
    filename = "/tmp/generate_throttle_configs_testfile-#{rand(0...10000)}"
    if content
      File.open(filename, 'w') do |f|
        f.write(content)
      end
    else
      FileUtils.touch(filename).first
    end
    at_exit do
      FileUtils.rm(filename)
    end
    filename
end
