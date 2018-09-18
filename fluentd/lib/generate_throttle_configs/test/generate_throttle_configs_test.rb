require_relative 'test_helper'

describe 'generate_throttle_configs' do

  before do
    @log_messages = {:warn=>[]}
    @log = Logger.new(STDOUT)
    @log.level = eval("Logger::#{ENV['LOG_LEVEL'] || 'ERROR'}")
    @log.instance_variable_set(:@log_messages, @log_messages)

    def @log.warn(msg)
      @log_messages[:warn] << msg
      super(msg)
    end

    @throttle_conf = create_test_file
    @input_conf = create_test_file
  end

  describe 'when throttle config exists and is empty' do

    it 'should produce a config with no exclusions' do
      generate_throttle_configs(@input_conf, @throttle_conf, @log)
      act = File.read(@input_conf)
      act.must_equal '<source>
  @type tail
  @id container-input
  @label @INGRESS
  path "/var/log/containers/*.log"
  pos_file "/var/log/es-containers.log.pos"
  tag kubernetes.*
  format json_or_crio
  keep_time_key true
  read_from_head "true"
  exclude_path []
</source>
'
    end

    describe 'and is configured to use alternate path and position files' do
        it 'should use the specified path and position' do
          options = {
            :cont_logs_path => '/tmp/foo/*.logs',
            :cont_pos_file => '/tmp/foo/test.logs.pos',
            :read_from_head => "false"
          }

      generate_throttle_configs(@input_conf, @throttle_conf, @log, options)
      act = File.read(@input_conf)
      act.must_equal '<source>
  @type tail
  @id container-input
  @label @INGRESS
  path "/tmp/foo/*.logs"
  pos_file "/tmp/foo/test.logs.pos"
  tag kubernetes.*
  format json_or_crio
  keep_time_key true
  read_from_head "false"
  exclude_path []
</source>
'
        end
    end

  end

  describe 'when throttle config exists and is not empty' do
#/var/log/containers/docker-registry-1-8md2d_default_registry-50192f5ef340512c3621d2122bbd995f738a654e0378646284008cdef0c3b143.log	00000000000830be	00000000021db8b3
    before do
      @throttle_conf = create_test_file('
firstproject:
  some_value_in_error: "abc"
  read_lines_limit: 100
secondproject:
  read_lines_limit: 200
')
      @pos_file = create_test_file('
/var/log/containers/docker-registry-1-8md2d_firstproject_registry-50192f5ef340512c3621d2122bbd995f738a654e0378646284008cdef0c3b143.log	00000000000830be	00000000021db8b3
/var/log/containers/docker-registry-1-8md2d_other_registry-50192f5ef340512c3621d2122bbd995f738a654e0378646284008cdef0c3b143.log	00000000000830be	00000000021db8b3
')
      @input_conf = create_test_file
      ENV['THROTTLE_PREFIX'] = '/tmp/test-input-docker-'
      ENV['CONT_POS_FILE_PREFIX'] = '/tmp/test-pos-file-'
      ENV['JSON_FILE_POS_FILE'] = @pos_file
      ENV['CONT_LOG_DIR'] = '/tmp'
      ENV['POS_FILE'] = @pos_file
    end

    after do
      ENV['THROTTLE_PREFIX'] = nil
      ENV['CONT_POS_FILE_PREFIX'] = nil
      ENV['JSON_FILE_POS_FILE'] = nil
      ENV['CONT_LOG_DIR'] = nil
      ENV['POS_FILE'] = nil
      FileUtils.rm_r Dir.glob('/tmp/test-input-docker-*')
      FileUtils.rm_r Dir.glob('/tmp/test-pos-file*')
    end

    it 'should produce a config with exclusions' do
      cont_log_dir = ENV['CONT_LOG_DIR']
      generate_throttle_configs(@input_conf, @throttle_conf, @log, :cont_pos_file=>@pos_file)
      act = File.read(@input_conf)
      act.must_equal"<source>
  @type tail
  @id container-input
  @label @INGRESS
  path \"/tmp/*.log\"
  pos_file \"#{@pos_file}\"
  tag kubernetes.*
  format json_or_crio
  keep_time_key true
  read_from_head \"true\"
  exclude_path [\"#{cont_log_dir}/*_firstproject_*.log\", \"#{cont_log_dir}/*_secondproject_*.log\"]
</source>
"
      {"firstproject"=>100, "secondproject"=>200}.each do |project,limit|
        throttle_file = "#{ENV['THROTTLE_PREFIX']}#{project}-#{Date.today.strftime('%Y%m%d')}.conf"
        pos_file = "#{ENV['CONT_POS_FILE_PREFIX']}#{project}.log.pos"
        File.exist?(throttle_file).wont_be_nil
        File.exist?(pos_file).wont_be_nil
        act = File.read(throttle_file)
        act.must_equal "<source>
  @type tail
  @id #{project}-input
  @label @INGRESS
  path /tmp/*_#{project}_*.log
  pos_file #{pos_file}
  read_lines_limit #{limit}
  tag kubernetes.*
  format json_or_crio
  keep_time_key true
  read_from_head \"true\"
</source>
"
        act =  File.read("#{ENV['CONT_POS_FILE_PREFIX']}firstproject.log.pos")
        act.must_equal "/var/log/containers/docker-registry-1-8md2d_firstproject_registry-50192f5ef340512c3621d2122bbd995f738a654e0378646284008cdef0c3b143.log	00000000000830be	00000000021db8b3\n"
      end

   end
  end

end
