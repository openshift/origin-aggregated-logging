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

DEFAULT_OPS_PROJECTS = ['default', 'openshift', 'openshift-infa']
DEFAULT_FILENAME = "/etc/fluent/configs.d/user/throttle-config.yaml"

VALID_SETTINGS = {"read_lines_limit" => "number"}

def get_file_name(name, isSyslog)
  ## file_name follows pattern: gen-#{name}-YYYYMMDD.conf ##

  file_name = if isSyslog
    "/etc/fluent/configs.d/dynamic/input-syslog-"
  else
    "/etc/fluent/configs.d/dynamic/input-docker-"
  end

  file_name << name
  file_name << "-"
  file_name << Date.today.strftime("%Y%m%d")
  file_name << ".conf"

  return file_name
end

def seed_file(file_name, project, isSyslog)

  pos_file = "/var/log/es-containers.log.pos"
  if project.eql?(".operations")
    if isSyslog
      path = "/var/log/messages"
      pos_file = "/var/log/node.log.pos"
    else
      path = DEFAULT_OPS_PROJECTS.map{|p| get_project_pattern(p)}.join(',')
    end
  else
    path = get_project_pattern(project)
  end

  File.open(file_name, 'w') { |file|
    @log.debug "Seeding #{file_name} with path: '#{path}' and pos_file: '#{pos_file}'"
    file.write(<<-CONF)
<source>
  @type tail
  @label @INGRESS
  path #{path}
  pos_file #{pos_file}
    CONF
  }
end

def write_to_file(project, key, value, isSyslog)

  file_name = get_file_name(project, isSyslog)

  # check if the file already exists, if not create it
  seed_file(file_name, project, isSyslog) if !File.exist?(file_name)

  File.open(file_name, 'a') { |file|
    @log.debug "Writing key: '#{key}' value: '#{value}' to file: #{file_name}"
    file.write(<<-CONF)
  #{key} #{value}
    CONF
  }

end

def close_file(project, isSyslog)
  file_name = get_file_name(project, isSyslog)
  
  if File.exist?(file_name)
    content = if isSyslog
      %(
  tag system.*
  format multiline
  # Begin possible multiline match: "Mmm DD HH:MM:SS "
  format_firstline /^[A-Z][a-z]{2}\\s+[0-3]?[0-9]\\s+[0-2][0-9]:[0-5][0-9]:[0-6][0-9]\\s/
  # extract metadata from same line that matched format_firstline
  format1 /^(?<time>\\S+\\s+\\S+\\s+\\S+)\\s+(?<host>\\S+)\\s+(?<ident>[\\w\\/\\.\\-]*)(?:\\[(?<pid>[0-9]+)\\])?[^\\:]*\\:\\s*(?<message>.*)$/
  time_format %b %d %H:%M:%S
  read_from_head true
  keep_time_key true
</source>
      )
    else
      %(
  time_format %Y-%m-%dT%H:%M:%S.%N%Z
  tag kubernetes.*
  format json
  keep_time_key true
  read_from_head true
</source>
      )
    end
    File.open(file_name, 'a') { |file|
      @log.debug "Closing file: #{file_name}"
      file.write(content)
    }
  end
end

def create_default_docker(excluded)

  file_name = "/etc/fluent/configs.d/dynamic/input-docker-default-docker.conf"

  content = %(
<source>
  @type tail
  @label @INGRESS
  path /var/log/containers/*.log
  pos_file /var/log/es-containers.log.pos
  time_format %Y-%m-%dT%H:%M:%S.%N%Z
  tag kubernetes.*
  format json
  keep_time_key true
  read_from_head true
  exclude_path #{excluded}
</source>
  )

  @log.debug "Writing content to #{file_name}: #{content}" 
  File.open(file_name, 'w') { |file|
    file.write(content)
  }
end

def create_default_syslog()

  file_name = "/etc/fluent/configs.d/dynamic/input-syslog-default-syslog.conf"

 # workaround for https://github.com/reevoo/fluent-plugin-systemd/issues/19
 # set read_from_head true
  content = if ENV['USE_JOURNAL'] == "true"
    %(
<source>
  @type systemd
  @label @INGRESS
  path "#{ENV['JOURNAL_SOURCE'] || '/run/log/journal'}"
  pos_file /var/log/journal.pos
  tag journal
  #{'read_from_head true' if ENV['JOURNAL_READ_FROM_HEAD'] == "true"}
</source>
    )
  else
    %(
<source>
  @type tail
  @label @INGRESS
  path /var/log/messages
  pos_file /var/log/node.log.pos
  tag system.*
  format multiline
  # Begin possible multiline match: "Mmm DD HH:MM:SS "
  format_firstline /^[A-Z][a-z]{2}\\s+[0-3]?[0-9]\\s+[0-2][0-9]:[0-5][0-9]:[0-6][0-9]\\s/
  # extract metadata from same line that matched format_firstline
  format1 /^(?<time>\\S+\\s+\\S+\\s+\\S+)\\s+(?<host>\\S+)\\s+(?<ident>[\\w\\/\\.\\-]*)(?:\\[(?<pid>[0-9]+)\\])?[^\\:]*\\:\\s*(?<message>.*)$/
  time_format %b %d %H:%M:%S
  read_from_head true
  keep_time_key true
</source>
    )
  end
  @log.debug "Writing content to #{file_name}: #{content}"
  File.open(file_name, 'w') { |file|
    file.write(content)
  }
end

def validate(key, value)
  # if the key is in valid settings, validate the value by required type
  if VALID_SETTINGS.keys.include?(key)
    case VALID_SETTINGS[key]
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

def get_project_pattern(name)

  project_pattern = "/var/log/containers/*_"
  project_pattern << name
  project_pattern << "_*.log"
end

filename = ENV['THROTTLE_CONF_LOCATION'] || DEFAULT_FILENAME
parsed = if File.exists?(filename)
             Hash[YAML.load_file(filename).map{|k,v|[k,v]}]
         else
            Hash.new
         end 

excluded = Array.new
excludeSyslog = false

# We do not yet support throttling logs read from the journal
unless ENV['USE_JOURNAL'] == "true"
  @log.info("Evaluating log trottle settings from #{filename}...")

  parsed.each { |name, options|
    @log.debug("Evaluating throttling for project '#{name}'")

    options.each_pair { |k,v|

      if validate(k,v)
        write_to_file(name, k, v, false)
        # build the list of paths the exclude
        if name.eql?(".operations")
          @log.debug("Found throttling settings for operations. Excluding projects: #{DEFAULT_OPS_PROJECTS}") 
          DEFAULT_OPS_PROJECTS.each do |p|
            excluded.push(get_project_pattern(p))
          end
          excludeSyslog = true
          write_to_file(name, k, v, true)
        else
          excluded.push(get_project_pattern(name))
        end
      else
        @log.warn "Invalid key/value pair {\"#{k}\":\"#{v}\"} provided -- ignoring..."
      end
      #}
    } if !options.nil?

    # if file was created, close it here
    close_file(name, false)
    close_file(name, true) if name.eql?(".operations")

  } if parsed.respond_to?( :each )
end

create_default_docker(excluded) unless ENV['USE_JOURNAL'] == "true"
create_default_syslog() unless excludeSyslog
