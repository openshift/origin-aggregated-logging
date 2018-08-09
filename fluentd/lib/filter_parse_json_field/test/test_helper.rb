require 'fileutils'

def create_test_file(content=nil)
    filename = "/tmp/filter_parse_json_field_testfile-#{rand(0...10000)}"
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
