basedir = File.dirname(__FILE__)

require 'logger'
require 'open3'
require 'yaml'
require 'multi_json'

require "#{basedir}/openshift_cli_wrapper/runner"

Dir.glob("#{basedir}/**/*.rb").each do |f|
    require f
end

MultiJson.use(:json_pure)

module OpenshiftCliWrapper

    LOGGER=Logger.new(ENV['LOGFILE']||'STDOUT', ENV['LOGLEVEL']||'info')

end
