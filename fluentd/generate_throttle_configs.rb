require 'json'
require 'date'
require 'logger'

# or should this be stderr?  -- we only want to print out warns?
@log = Logger.new(STDOUT)
@log.level = Logger::WARN

@Valid_Settings = {"buffer_chunk_limit" => "size", "buffer_queue_limit" => "number", "flush_interval" => "time", "flush_at_shutdown" => "boolean", "max_retry_wait" => "time", "disable_retry_limit" => "boolean", "retry_limit" => "number", "retry_wait" => "time", "num_threads" => "number"}

def get_file_name(name)
  ## file_name follows pattern: gen-#{name}-YYYYMMDD.conf ##

  file_name = "/etc/fluent/configs.d/output/gen-"
  file_name << name
  file_name << "-"
  file_name << Date.today.strftime("%Y%m%d")
  file_name << ".conf"

  return file_name
end

def seed_file(file_name, project)

  File.open(file_name, 'w') { |file|
    file.write("<match **_#{project}_**>\n@type forward\nsend_timeout 60s\nrecover_wait 10s\nheartbeat_interval 1s\nphi_threshold 16\nhard_timeout 60s\n##\n")
  }

end

def write_to_file(project, key, value)

  file_name = get_file_name(project)

  # check if the file already exists, if not create it
  seed_file(file_name, project) if !File.exist?(file_name)

  File.open(file_name, 'a') { |file|
    file.write("#{key} #{value}\n")
  }

end

def close_file(project)
  file_name = get_file_name(project)

  File.open(file_name, 'a') { |file|
    file.write("##\n<server>\nname '127.0.0.1:24224'\nhost 127.0.0.1\nport 24224\n</server>\n</match>")
  } if File.exist?(file_name)
end

def validate(key, value)

  #@log.info "Checking #{key} and #{value}"

  # if the key is in valid settings, validate the value by required type
  if @Valid_Settings.keys.include?(key)
    case @Valid_Settings[key]
    when "time"
      valid = value.to_s.match('^\d+[sSmMhH]$') { |m| if m.nil?; false; else m.to_s.match('\d+').to_s.to_i > 0 end }
    when "size"
      valid = value.to_s.match('^\d+[kKmMgG]$') { |m| if m.nil?; false; else m.to_s.match('\d+').to_s.to_i > 0 end }
    when "number"
      valid = value.to_s.match('^\d+$') { |m| if m.nil?; false; else m.to_s.to_i > 0 end }
    when "boolean"
      valid = value.to_s.match('^true$|^false$') { |m| !m.nil? }
    else
      #unknown type
      return false
    end
  else
    @log.warn "Unknown option \"#{key}\""
    return false
  end

  if !valid
    @log.warn "Invalid value type matched for \"#{value}\""
  end

  return valid
end

settings = ARGV[0]

parsed = ""
parsed = JSON.parse(settings) if !settings.nil?

parsed.each { |project|
  name = project[0]
  options = project[1]

  options['options'].each { |option|

    option.each_pair { |k,v|

      if validate(k,v)
        write_to_file(name, k, v)
      else
        @log.warn "Invalid key/value pair {\"#{k}\":\"#{v}\"} provided -- ignoring..."
      end
    }

  } if !options.nil?

  # if file was created, close it here
  close_file(name)

} if parsed.respond_to?( :each )
