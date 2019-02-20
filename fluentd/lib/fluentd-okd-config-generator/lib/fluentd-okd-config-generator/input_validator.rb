module FluentdOKDConfigGenerator

    class ConfigGeneratorError < RuntimeError
    end

    class InputValidator

        STDOUT = 0

        def initialize(logger)

        end

        def validate!(options)
            validate_file(:input_file, options[:input_file])
            validate_int(:max_targets, options[:max_targets]) if options[:max_targets]
        end

        def validate_file(arg, file)
            raise ConfigGeneratorError.new("#{arg} is nil") if file.nil? 
            raise ConfigGeneratorError.new("#{arg} does not exist") unless File.exists?(file)
        end

        def validate_int(arg, value)
            return if value.is_a?(Numeric) && value > 0
            raise ConfigGeneratorError.new("#{arg} must be numeric and greater then 0")
        end

    end
end