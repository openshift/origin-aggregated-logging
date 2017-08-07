
module OpenshiftCliWrapper

    class Logger

        OFF = 'OFF'

        def initialize(file, level)
            file = STDOUT if file.nil?
            @loglevel = level.nil? ? ::Logger::ERROR : ::Logger.const_get(level.upcase)
            if @loglevel != OFF
              file = file == 'STDOUT' ? STDOUT : file
              @logger = ::Logger.new(file)
              @logger.level = @loglevel
            end
        end

        [:info, :warn, :debug, :error, :fatal].each do |level|
            instance_eval do 
                define_method level do | msg |
                    @logger.method(level.to_sym).call(msg) unless @loglevel == OFF
                end
            end
        end
        
    end
    
end
