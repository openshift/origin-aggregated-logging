require 'yaml'

module FluentdOKDConfigGenerator

    
    module PipelineInputLoader
        def symbolize_keys(hash, ignore_top=true)
            hash.inject({}){|result, (key, value)|
                new_key = key.is_a?(String) && !ignore_top ? key.to_sym : key
                new_value = case value
                            when Hash then symbolize_keys(value, false)
                            when Array then value.collect {|t|symbolize_keys(t, false)}
                            else value
                            end
                result[new_key] = new_value
                result
            }
        end
        
        def load_pipeline_input(input_file, logger: @logger)
            input = YAML::load_file(input_file)
            input = symbolize_keys(input, true)
            logger.debug("Loaded input file #{input_file}: #{input}")
            input = input.reject do |source, config|
                logger.debug("Removing sources from input with no targets...")
                case
                when config.nil?
                    logger.warn("Skipping source #{source} because the value is nil")
                    true
                when !config.is_a?(Hash)
                    logger.warn("Skipping source #{source} because the value is not a Hash")
                    true
                when config[:targets].nil?
                    logger.warn("Skipping source #{source} because targets is not a Hash")
                    true
                when config [:targets].length == 0
                    logger.warn("Skipping source #{source} because targets is empty")
                    true
                else
                    false
                end
            end
        end

        def sanitize_input!(input, max_targets_per_source, logger: @logger)
            input.each do |source, config|
                if config[:targets].length > max_targets_per_source
                    logger.info("Truncating number of targets for #{source} to #{max_targets_per_source}")
                end
                config[:targets].each_index do |i|
                    config[:targets].delete_at(i) if i >= max_targets_per_source
                end
            end
        end
    end
end