require "strptime/version"
begin
  require "strptime/#{RUBY_VERSION[/\d+.\d+/]}/strptime"
rescue LoadError
  require "strptime/strptime"
end

class Strptime
  # Your code goes here...
end
