require 'yaml'
require 'date'
require 'logger'

@log = Logger.new(STDOUT)
@log.level = Logger::WARN

@Valid_Settings = {"read_lines_limit" => "number"}

def get_file_name(name, isSyslog)
  ## file_name follows pattern: gen-#{name}-YYYYMMDD.conf ##

  file_name = "/etc/fluent/configs.d/input/docker/gen-" unless isSyslog
  file_name = "/etc/fluent/configs.d/input/syslog/gen-" if isSyslog
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
      path = "/var/log/messages*"
      pos_file = "/var/log/node.log.pos"
    else
      path = get_project_pattern("default")
      path << ","
      path << get_project_pattern("openshift")
      path << ","
      path << get_project_pattern("openshift-infra")
    end
  else
    path = get_project_pattern(project)
  end

  File.open(file_name, 'w') { |file|
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
    file.write(<<-CONF)
  #{key} #{value}
    CONF
  }

end

def close_file(project, isSyslog)
  file_name = get_file_name(project, isSyslog)

  if isSyslog
    File.open(file_name, 'a') { |file|
      file.write(<<-CONF)
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
    CONF
    } if File.exist?(file_name)
  else
    File.open(file_name, 'a') { |file|
      file.write(<<-CONF)
  time_format %Y-%m-%dT%H:%M:%S
  tag kubernetes.*
  format json
  keep_time_key true
  read_from_head true
</source>
    CONF
    } if File.exist?(file_name)
  end
end

def create_default_docker(excluded)

  file_name = "/etc/fluent/configs.d/input/docker/default-docker.conf"

  File.open(file_name, 'w') { |file|
    file.write(<<-CONF)
<source>
  @type tail
  @label @INGRESS
  path /var/log/containers/*.log
  pos_file /var/log/es-containers.log.pos
  time_format %Y-%m-%dT%H:%M:%S
  tag kubernetes.*
  format json
  keep_time_key true
  read_from_head true
  exclude_path #{excluded}
</source>
    CONF
  }
end

def create_default_syslog()

  file_name = "/etc/fluent/configs.d/input/syslog/default-syslog.conf"

  File.open(file_name, 'w') { |file|
    file.write(<<-CONF)
<source>
  @type tail
  @label @INGRESS
  path /var/log/messages*
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
    CONF
  }
end

def validate(key, value)
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

def get_project_pattern(name)

  project_pattern = "/var/log/containers/*_"
  project_pattern << name
  project_pattern << "_*.log"
end

filename = "#{ENV['THROTTLE_CONF_LOCATION']}/settings"

parsed = ""
parsed = YAML.load_file(filename) if File.exists?(filename)

excluded = Array.new
excludeSyslog = false

parsed.each { |project|
  name = project[0]
  options = project[1]

  options.each_pair { |k,v|

      if validate(k,v)
        write_to_file(name, k, v, false)
        # build the list of paths the exclude
        excluded.push(get_project_pattern(name)) unless name.eql?(".operations")

        if name.eql?(".operations")
          excluded.push(get_project_pattern("default"))
          excluded.push(get_project_pattern("openshift"))
          excluded.push(get_project_pattern("openshift-infra"))

          excludeSyslog = true
          write_to_file(name, k, v, true)
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

create_default_docker(excluded)
create_default_syslog() unless excludeSyslog
