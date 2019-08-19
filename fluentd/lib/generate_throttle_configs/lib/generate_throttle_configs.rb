require 'yaml'
require 'date'
require 'logger'

log_level = ENV['LOG_LEVEL'] || 'WARN'
log = Logger.new(STDOUT)

begin
  log.level = eval("Logger::#{log_level}")
rescue
  log.level = Logger::WARN
  log.warn "#{log_level} is not a valid value. Must be one of: DEBUG, WARN, INFO, ERROR"
  log.warn "Setting log level to WARN"
end

ENV.sort.each do |entry|
  log.debug entry
end if log.debug?

DEFAULT_OPS_PROJECTS = !ENV['OCP_OPERATIONS_PROJECTS'].nil? ? ENV['OCP_OPERATIONS_PROJECTS'].split(' ') : ['default', 'openshift', 'openshift-infra', 'kube-system']
DEFAULT_FILENAME = "/etc/fluent/configs.d/user/throttle-config.yaml"

VALID_SETTINGS = {"read_lines_limit" => "number"}
CONTAINER_LOG_DRIVER = (ENV['USE_CRIO'] == 'true') ? "CRIO" : "JSON_FILE"
POS_FILE = CONTAINER_LOG_DRIVER + "_POS_FILE"
READ_FROM_HEAD = CONTAINER_LOG_DRIVER + "_READ_FROM_HEAD"
CONT_LOGS_PATH = CONTAINER_LOG_DRIVER + "_PATH"

def cont_pos_file
  ENV[POS_FILE] || '/var/log/es-containers.log.pos'
end

def get_cont_pos_file_name(name)
  prefix = ENV['CONT_POS_FILE_PREFIX']||'/var/log/es-container-' 
  "#{prefix}#{name}.log.pos"
end

def get_file_name(name)
  ## file_name follows pattern: gen-#{name}-YYYYMMDD.conf ##

  file_name = ENV['THROTTLE_PREFIX']||'/etc/fluent/configs.d/dynamic/input-docker-'
  file_name = file_name + name
  file_name << '-'
  file_name << Date.today.strftime('%Y%m%d')
  file_name << '.conf'

  return file_name
end

def get_time_format(options)
  options[:use_crio] ? '%Y-%m-%dT%H:%M:%S.%N%:z' : '%Y-%m-%dT%H:%M:%S.%N%Z'
end

def get_output_label(options)
  (options[:use_crio] || options[:use_multiline_json]) ? '@CONCAT' : '@INGRESS'
end

def get_logfile_format(options)
  options[:use_crio] ? '/^(?<time>.+) (?<stream>stdout|stderr)( (?<logtag>.))? (?<log>.*)$/' : 'json'
end

## Returns the names of all throttle configs for parsing through when reverting
def get_all_throttle_files()
  return Dir.glob('/var/log/es-container-*.log.pos')
end

def get_refresh_interval()
  return ENV['CONTAINER_LOGS_REFRESH_INTERVAL'] || '5'
end

def get_rotate_wait()
  return ENV['CONTAINER_LOGS_ROTATE_WAIT'] || '5'
end

def move_pos_file_project_entry(source_file, dest_file, project, log)
  log.debug "moving project #{project} pos entry from #{source_file} to #{dest_file}"
  if File.file?(source_file)
    project_pattern = ".*_#{project}_.*\.log"

    matches = Array.new
    File.open(source_file) { |file|
      file.grep(/#{project_pattern}/) { |match| matches << match }
    }
    log.debug("Found #{matches.length} in position file for project #{project}")

    update = ""
    update = File.read(dest_file) if File.file?(dest_file)
    matches.each { |match|
      log_file_pattern = Regexp.escape(match.split(" ")[0])
      update.gsub!(/#{log_file_pattern}.*$\n/, "")
      ## We are clearing out the line while if it exists and then appending the source_file line
      update << match
    }
    File.open(dest_file, "w") { |file| file.write update }

    ## Remove matches from the old file now that they're safely in the new file
    update = File.read(source_file)
    matches.each { |match|
      log_file_pattern = Regexp.escape(match.split(" ")[0])
      update.gsub!(/#{log_file_pattern}.*$\n/, "")
    }
    File.open(source_file, "w") { |file| file.write update }
  else
    log.info("#{source_file} position file does not exist")
  end

end

## This will copy the pos entries from the throttle configs back to the default pos file
def revert_throttle(log)
  get_all_throttle_files.each { |file_name| move_pos_file_project_entry(file_name, cont_pos_file, '.*', log) }
end

def seed_file(file_name, project, log)

  if project.eql?('.operations')
    path = DEFAULT_OPS_PROJECTS.map{|p| get_project_pattern(p)}.join(',')

    ## openshift-* is a protected project prefix -- so users would not be able to create
    ## a project that starts with this. Guard taken to prevent possible collision with a
    ## user created project 'operations'
    pos_file = get_cont_pos_file_name('openshift-operations')
  else
    path = get_project_pattern(project)
    pos_file = get_cont_pos_file_name(project)
  end

  File.open(file_name, 'w') { |file|
    log.debug "Seeding #{file_name} with path: '#{path}' and pos_file: '#{pos_file}'"
    file.write(<<-CONF)
<source>
  @type tail
  @id #{project}-input
  path #{path}
  pos_file #{pos_file}
  refresh_interval #{get_refresh_interval}
  rotate_wait #{get_rotate_wait}
    CONF
  }

  # Set up the initial pos file in case we had already read from container files
  move_pos_file_project_entry(cont_pos_file, pos_file, project, log) unless project.eql?('.operations')
  DEFAULT_OPS_PROJECTS.each{ |ops_project| move_pos_file_project_entry(cont_pos_file, pos_file, ops_project, log) } if project.eql?('.operations')
end

def write_to_file(project, key, value, log)

  file_name = get_file_name(project)

  # check if the file already exists, if not create it
  seed_file(file_name, project, log) if !File.exist?(file_name)

  File.open(file_name, 'a') { |file|
    log.debug "Writing key: '#{key}' value: '#{value}' to file: #{file_name}"
    file.write(<<-CONF)
  #{key} #{value}
    CONF
  }

end

def close_project_file(project, log, options)
  file_name = get_file_name(project)
  close_file(file_name, log, options)
end

def close_file(file_name, log, options)
  use_crio = options[:use_crio]
  use_multiline_json = options[:use_multiline_json]
  File.open(file_name, 'a') { |file|
    log.debug "Closing file: #{file_name}"
    file.write(<<-CONF)
  time_format #{get_time_format(options)}
  tag kubernetes.*
  format #{get_logfile_format(options)}
  keep_time_key true
  read_from_head "#{options[:read_from_head] || 'true'}"
  @label #{get_output_label(options)}
</source>
    CONF
    if use_crio || use_multiline_json
      file.write(<<-CONFMULTI1)
<label #{get_output_label(options)}>
  <filter kubernetes.**>
    @type concat
    key log
    separator ""
    CONFMULTI1
      if use_crio
        file.write(<<-CONFCRIO)
    partial_key logtag
    partial_value P
    CONFCRIO
      else
        file.write(<<-CONFJSONFILE)
    multiline_end_regexp /\\n$/
    CONFJSONFILE
      end
      file.write(<<-CONFMULTI2)
  </filter>
  <match kubernetes.**>
    @type relabel
    @label @INGRESS
  </match>
</label>
    CONFMULTI2
    end
  } if File.exist?(file_name)
end

def create_default_docker(input_conf_file, excluded, log, options)
  cont_logs_path = options[:cont_logs_path] || '/var/log/containers/*.log'
  cont_pos_file = options[:cont_pos_file] || '/var/log/es-containers.log.pos'

  File.open(input_conf_file, 'w') { |file|
    log.debug "Creating default docker input config file #{input_conf_file}"
    file.write(<<-CONF)
<source>
  @type tail
  @id docker-input
  path "#{cont_logs_path}"
  pos_file "#{cont_pos_file}"
  refresh_interval #{get_refresh_interval}
  rotate_wait #{get_rotate_wait}
  exclude_path #{excluded}
  CONF
  }
  close_file(input_conf_file, log, options)
  log.debug "Created default docker input config file"
end

def validate(key, value, log)
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
    log.warn "Unknown option \"#{key}\""
    return false
  end

  if !valid
    log.warn "Invalid value type matched for \"#{value}\""
  end

  return valid
end

def get_project_pattern(name)
  dir = ENV['CONT_LOG_DIR']||'/var/log/containers'
  "#{dir}/*_#{name}_*.log"
end

def generate_throttle_configs(input_conf, throttle_conf_file, log, init_options={})
if init_options[:use_crio] && init_options[:use_multiline_json]
  raise "Cannot use both USE_CRIO=true and USE_MULTILINE_JSON=true"
end
begin
  parsed = if File.exist?(throttle_conf_file) && (hsh = YAML.load_file(throttle_conf_file)) && hsh.respond_to?(:map)
             log.debug "throttle hash #{hsh}"
             Hash[hsh.map{|k,v|[k,v]}]
           else
             Hash.new
           end
rescue Exception => ex
  log.warn "Could not parse YAML file #{throttle_conf_file} : #{ex} - ignoring..."
  parsed = Hash.new
end

excluded = Array.new
throttling = false
# We do not yet support throttling logs read from the journal
# So we don't support throttling operations logs here - use the journald
# journald.conf to do that
parsed.each do |name,options|
  log.info("Evaluating log throttle settings from #{throttle_conf_file} #{name} #{options}...")
  # YAML parser allows some strange things . . .
  unless name.class.eql?(String)
    log.warn "Invalid value #{name} for project name -- ignoring..."
    next
  end
  unless options.class.eql?(Hash)
    log.warn "Invalid value #{options} for options project #{name} -- ignoring..."
    next
  end

  needclose = false
  options.each { |k,v|
    log.debug("Evaluating throttling for project '#{name}'")
    if validate(k,v, log)
      write_to_file(name, k, v, log)
      needclose = true
      throttling = true if !throttling

      if name.eql?('.operations')
        log.debug("Found throttling settings for operations. Excluding projects: #{DEFAULT_OPS_PROJECTS}")
        DEFAULT_OPS_PROJECTS.each do |p|
          excluded.push(get_project_pattern(p))
        end
      else
        excluded.push(get_project_pattern(name))
      end
    else
      log.warn "Invalid key/value pair {\"#{k}\":\"#{v}\"} provided -- ignoring..."
    end
  } if !options.nil?

  # if file was created, close it here
  close_project_file(name, log, init_options) if needclose
end

revert_throttle(log) unless throttling

create_default_docker(input_conf, excluded, log, init_options)

end

if __FILE__ == $0
    generate_throttle_configs('/etc/fluent/configs.d/dynamic/input-docker-default-docker.conf',
                              ENV['THROTTLE_CONF_LOCATION'] || DEFAULT_FILENAME,
                              log,
                              :cont_logs_path=>"#{ENV[CONT_LOGS_PATH] || '/var/log/containers/*.log'}",
                              :cont_pos_file=>"#{ENV[POS_FILE] || '/var/log/es-containers.log.pos'}",
                              :use_crio=>(ENV['USE_CRIO'] == 'true'),
                              :use_multiline_json=>(ENV['USE_MULTILINE_JSON'] == 'true'),
                              :read_from_head=>ENV[READ_FROM_HEAD] || 'true')
end

