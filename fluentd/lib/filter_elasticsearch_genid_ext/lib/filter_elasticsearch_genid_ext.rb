require 'securerandom'
require 'base64'
require 'fluent/filter'

begin
  GenidMatchClass = Fluent::Match
rescue
  # Fluent::Match not provided with 0.14
  class GenidMatchClass
    def initialize(pattern_str, unused)
      patterns = pattern_str.split(/\s+/).map {|str|
        Fluent::MatchPattern.create(str)
      }
      if patterns.length == 1
        @pattern = patterns[0]
      else
        @pattern = Fluent::OrMatchPattern.new(patterns)
      end
    end
    def match(tag)
      @pattern.match(tag)
    end
    def to_s
      "#{@pattern}"
    end
  end
end

module Fluent
  class ElasticsearchGenidExtFilter < Filter
    Fluent::Plugin.register_filter('elasticsearch_genid_ext', self)

    desc 'key to store generated unique id or the value of alt_key if specified'
    config_param :hash_id_key, :string, :default => '_hash'
    desc 'key for the hash "record" (optional)'
    config_param :alt_key, :string, default: ""
    desc 'process alt_key in records with this tag pattern'
    config_param :alt_tags, :string, default: ""

    def configure(conf)
      super
      @alt_keys = @alt_key.split('.')
      @alt_tag_matcher = GenidMatchClass.new(@alt_tags, nil)
    end

    def filter(tag, time, record)
      record[@hash_id_key] = ""
      if @alt_tag_matcher.match(tag)
        myid = nil
        unless @alt_key.to_s.strip.empty? || record.empty?
          myid = record
          @alt_keys.each do |p|
            unless myid.key?(p)
              unless p.eql? @alt_key
                log.on_debug do
                  log.debug "filter:elasticsearch_genid_ext: #{p} in alt_key #{@alt_key} is not a key of record."
                end
                myid = nil
              end
              break
            end
            myid = myid[p]
          end
        end
        record[@hash_id_key] = if myid.is_a? String
                                 myid
                               else
                                 Base64.strict_encode64(SecureRandom.uuid)
                               end
      end
      if record[@hash_id_key].to_s.strip.empty?
          record[@hash_id_key] = Base64.strict_encode64(SecureRandom.uuid)
      end
      record
    end

  end
end
