
module OpenshiftCliWrapper

    module Runner

        def execute(cmd)
            LOGGER.debug("cmd: #{cmd.join(' ')}")
            stdout, stderr, result_code = Open3.capture3(cmd.join(' '))
            LOGGER.debug("code: #{result_code}")
            LOGGER.debug("out: #{stdout}") unless stdout.nil? || stdout.length == 0
            LOGGER.debug("err: #{stderr}") unless stderr.nil? || stderr.length == 0
            result = {
              stdout: stdout,
              stderr: stderr,
              result_code: result_code
            }
            
            def result.success?
              self[:result_code].success?
            end

            result
        end
    end
end
