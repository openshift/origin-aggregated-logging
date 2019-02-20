require File.join(File.dirname(__FILE__), '..', 'lib/fluentd-okd-config-generator') 
require 'minitest/autorun'

def logger()
   logger =  Logger.new(STDOUT)
   logger.level = ENV['LOGLEVEL'].nil? ? Logger::ERROR : Logger::DEBUG
   logger
end
