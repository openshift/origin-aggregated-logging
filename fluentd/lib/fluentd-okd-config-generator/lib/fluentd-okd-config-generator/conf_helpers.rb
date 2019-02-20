module FluentdOKDConfigGenerator
    module ConfHelpers

        def process
            template = load_template(@template_name)
            ERB.new(template,  nil, "%<>>-").result( binding )
        end
        
        def load_template(template_name)
            File.read( File.join(File.dirname(__FILE__),"templates",template_name))
        end

        def label_name(source)
            "@#{source.split('.').join('_').upcase()}"
        end

        # include_file a partial template named 'target'
        # tabs is optional to  effect formatting which
        #      assumes each 'tab' is 4 spaces
        def include_file(target, options = {conf_type: :store, tabs: nil, context: nil})
            conf_type = options[:conf_type]||:store
            tabs = options[:tabs]
            @context = options[:context]
            @target = target
            prefix = tabs ? ' ' * tabs * 4 : ''
            template = load_template("#{conf_type}_#{target[:type]}.erb")
            out = ERB.new(template,  nil, "%<>>-").result( binding ).split("\n")
            out = ([out[0]] + out[1,out.length].collect do | line |
                line.strip == '' ? nil : "#{prefix}#{line}"
            end).compact.join("\n") + "\n"
        end
    end
end
