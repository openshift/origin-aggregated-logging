module FluentdOKDConfigGenerator
    
    #
    # Generate the 'match' blocks for the @OUTPUT label
    # to split source messages to source labels
    #
    class OutputLabelMatches
        include ConfHelpers
        def initialize(source, tags)
            @template_name = 'output_label_match.erb'
            @label_name = label_name(source)
            @tags = tags
        end
    end
    
    #
    # Generate the source labels to match and split for each target label
    #
    class SourceLabelConf
        include ConfHelpers
        def initialize(source, targets)
            @template_name = 'source_label.erb'
            @source = source
            @targets = targets
            @label_name = label_name(source)
        end
        
        def relabel(target)
            "#{@label_name}_#{target[:type].upcase()}#{target[:counter]}"
        end
    end
    
    #
    # Generate the target label blocks for each endpoint
    #
    class EndpointLabelConf

        include ConfHelpers

        def initialize(source, target)
            @template_name = 'endpoint_label.erb'
            @source = source
            @target = target
            set_and_format_label_name(source, target)
            set_and_format_retry_tag(source)
        end

        def store_id(target, context)
            store_id = "#{target[:store_id]}#{target[:counter]}"
            context == :prefix_as_retry ? "retry_#{store_id}" : store_id
        end

        def buffer_path(target, context)
            "/var/lib/fluentd/#{store_id(target,context)}"
        end

        def set_and_format_label_name(source, target)
            @label_name = "@#{source.split('.').join('_').upcase()}_#{target[:type].upcase()}#{target[:counter]}"
        end
        
        def set_and_format_retry_tag(source)
            @retry_tag = "retry_#{source.split('.').join('_').downcase()}"
        end
    end

    class Generator
        def initialize(logger)
            @log = logger
        end

        def generate(input)
            @log.debug("Generating config for input: #{input}")
            results = input.collect do | source, config |
                gen_output_conf(source, config[:targets])
            end
            @log.debug("Results: #{results}")
            "".tap do | buffer |
                results.each do |conf|
                    buffer << "\n"
                    conf.each do | k, value|
                        buffer << value.join('\n')
                    end
                end 
            end
        end
        
        def gen_output_label_match_confs(sources, tags)
            @log.debug("Generating output label match blocks for source keys '#{sources}': #{tags}")
            sources.sort! do |first,second|
                case 
                when first == 'logs.app'
                    1
                when second == 'logs.app'
                    1
                else
                    0
                end
            end
            sources.collect do |source|
                if tags && tags.key?(source)
                    OutputLabelMatches.new(source,tags[source]).process() 
                else
                    @log.warn("Dropping @OUTPUT label match generation for source '#{source}' as there are no known fluent tags to properly route them")
                end
            end.compact
        end

        def gen_endpoint_conf(source, target)
            EndpointLabelConf.new(source, target).process()
        end
        
        def gen_output_conf(source, targets)
            @log.debug("Generating output conf for source: #{source}")
            counters = { elasticsearch: 0}
            targets = targets.collect do |target|
                begin
                    @log.debug("Generating output conf for target: #{target[:type]}")
                    case target[:type]
                    when 'elasticsearch'
                        target[:store_id] = "#{source.split('.').join('_').downcase()}_elasticsearch"
                        endpoint = target[:endpoint].split(':')
                        target[:host] = endpoint.first
                        target[:port] = endpoint.length == 1 ? "9200" : endpoint[1]
                        target[:counter] = counters[:elasticsearch]
                        counters[:elasticsearch] += 1
                        target
                    else
                        @log.warn("Skipping unrecognized type '#{in_config[:type]}' while generating output config")
                    end
                rescue=>e
                    @log.error("Error generating target conf: #{e}")
                end
            end
            {}.tap do | results |
                results[:source_labels] = [SourceLabelConf.new(source, targets).process()]
                results[:endpoints] = targets.collect { |t| gen_endpoint_conf(source, t) }
            end
        end

    end
end
