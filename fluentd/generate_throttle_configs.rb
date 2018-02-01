require 'yaml'
require 'date'
require 'logger'

log_level = ENV['LOG_LEVEL'] || 'WARN'
@log = Logger.new(STDOUT)

begin
  @log.level = eval("Logger::#{log_level}")
rescue
  @log.level = Logger::WARN
  @log.warn "#{log_level} is not a valid value. Must be one of: DEBUG, WARN, INFO, ERROR"
  @log.warn "Setting log level to WARN"
end

ENV.sort.each do |entry|
  @log.debug entry
end if @log.debug?

DEFAULT_OPS_PROJECTS = ['default', 'openshift', 'openshift-infra']
DEFAULT_FILENAME = "/etc/fluent/configs.d/user/throttle-config.yaml"

VALID_SETTINGS = {"read_lines_limit" => "number"}

def json_pos_file
  ENV['JSON_FILE_POS_FILE'] || '/var/log/es-containers.log.pos'
end

def get_file_name(name)
  ## file_name follows pattern: gen-#{name}-YYYYMMDD.conf ##

  file_name = '/etc/fluent/configs.d/dynamic/input-docker-'
  file_name << name
  file_name << '-'
  file_name << Date.today.strftime('%Y%m%d')
  file_name << '.conf'

  return file_name
end

def seed_file(file_name, project)

  if project.eql?('.operations')
    path = DEFAULT_OPS_PROJECTS.map{|p| get_project_pattern(p)}.join(',')
  else
    path = get_project_pattern(project)
  end

  File.open(file_name, 'w') { |file|
    @log.debug "Seeding #{file_name} with path: '#{path}' and pos_file: '#{json_pos_file}'"
    file.write(<<-CONF)
<source>
  @type tail
  @label @INGRESS
  path #{path}
  pos_file #{json_pos_file}
    CONF
  }
end

def write_to_file(project, key, value)

  file_name = get_file_name(project)

  # check if the file already exists, if not create it
  seed_file(file_name, project) if !File.exist?(file_name)

  File.open(file_name, 'a') { |file|
    @log.debug "Writing key: '#{key}' value: '#{value}' to file: #{file_name}"
    file.write(<<-CONF)
  #{key} #{value}
    CONF
  }

end

def close_file(project)
  file_name = get_file_name(project)

  File.open(file_name, 'a') { |file|
    @log.debug "Closing file: #{file_name}"
    file.write(<<-CONF)
  time_format %Y-%m-%dT%H:%M:%S.%N%Z
  tag kubernetes.*
  format json
  keep_time_key true
  read_from_head "#{ENV['JSON_FILE_READ_FROM_HEAD'] || 'true'}"
</source>
    CONF
  } if File.exist?(file_name)
end

def create_default_docker(excluded)

  file_name = '/etc/fluent/configs.d/dynamic/input-docker-default-docker.conf'

  File.open(file_name, 'w') { |file|
    @log.debug "Creating default docker input config file #{file_name}"
    file.write(<<-CONF)
<source>
  @type tail
  @label @INGRESS
  path "#{ENV['JSON_FILE_PATH'] || '/var/log/containers/*.log'}"
  pos_file "#{ENV['JSON_FILE_POS_FILE'] || '/var/log/es-containers.log.pos'}"
  time_format %Y-%m-%dT%H:%M:%S.%N%Z
  tag kubernetes.*
  format json
  keep_time_key true
  read_from_head "#{ENV['JSON_FILE_READ_FROM_HEAD'] || 'true'}"
  exclude_path #{excluded}
</source>
    CONF
  }
end

def validate(key, value)
  # if the key is in valid settings, validate the value by required type
  if VALID_SETTINGS.keys.include?(key)
    case VALID_SETTINGS[key]
    when 'time'
      valid = value.to_s.match('^\d+[sSmMhH]$') { |m| if m.nil?; false; else m.to_s.match('\d+').to_s.to_i > 0 end }
    when 'size'
      valid = value.to_s.match('^\d+[kKmMgG]$') { |m| if m.nil?; false; else m.to_s.match('\d+').to_s.to_i > 0 end }
    when 'number'
      valid = value.to_s.match('^\d+$') { |m| if m.nil?; false; else m.to_s.to_i > 0 end }
    when 'boolean'
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

def get_project_pattern(name)
  "/var/log/containers/*_#{name}_*.log"
end

filename = ENV['THROTTLE_CONF_LOCATION'] || DEFAULT_FILENAME
begin
  parsed = if File.exists?(filename) && (hsh = YAML.load_file(filename)) && hsh.respond_to?(:map)
             @log.debug "throttle hash #{hsh}"
             Hash[hsh.map{|k,v|[k,v]}]
           else
             Hash.new
           end
rescue Exception => ex
  @log.warn "Could not parse YAML file #{filename} : #{ex} - ignoring..."
  parsed = Hash.new
end

excluded = Array.new
# We do not yet support throttling logs read from the journal
# So we don't support throttling operations logs here - use the journald
# journald.conf to do that
parsed.each { |name,options|
  @log.info("Evaluating log throttle settings from #{filename} #{name} #{options}...")
  # YAML parser allows some strange things . . .
  unless name.class.eql?(String)
    @log.warn "Invalid value #{name} for project name -- ignoring..."
    next
  end
  unless options.class.eql?(Hash)
    @log.warn "Invalid value #{options} for options project #{name} -- ignoring..."
    next
  end

  needclose = false
  options.each_pair { |k,v|
    @log.debug("Evaluating throttling for project '#{name}'")
    if validate(k,v)
      write_to_file(name, k, v)
      needclose = true

      if name.eql?('.operations')
        @log.debug("Found throttling settings for operations. Excluding projects: #{DEFAULT_OPS_PROJECTS}")
        DEFAULT_OPS_PROJECTS.each do |p|
          excluded.push(get_project_pattern(p))
        end
      else
        excluded.push(get_project_pattern(name))
      end
    else
      @log.warn "Invalid key/value pair {\"#{k}\":\"#{v}\"} provided -- ignoring..."
    end
  } if !options.nil?

  # if file was created, close it here
  close_file(name) if needclose
}

create_default_docker(excluded)
