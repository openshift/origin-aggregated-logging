# ref - http://www.goodercode.com/wp/convert-your-hash-keys-to-object-properties-in-ruby/
class ::Hash
  def method_missing(name, *args, &block)
    return self[name] if key? name
    self.each { |k,v| return v if k.to_s.to_sym == name }
    super.method_missing(name, *args, &block)
  end
end

module OpenshiftCliWrapper

    class StructuredOutputFormatter

        def parse(out_type, output)
            if out_type == 'yaml'
              return YAML.load(output)
            elsif out_type == 'json'
              return MultiJson.load(output)
            end
            output
        end

    end
end
