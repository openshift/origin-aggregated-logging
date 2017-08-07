
module OpenshiftCliWrapper

    class Command
        attr :args
        attr_reader :name

        def initialize(name)
            @name = name
            @args = {}
        end

        def arg(key,value)
            args[key]=value
        end

        def set(var, value)
            instance_variable_set("@#{var.to_s}", value)
        end

        def format(binary, args)
            [binary].concat(sanitize(args))
        end

        def format_options(args)
            [].tap do |options|
              args.each do |k,v| 
                  value = "#{k}"
                  value << "='#{v}'" unless v.nil?
                  options << value
              end
            end
        end

    end

    module Get
        # return on_error_default instead of error
        def get(resource, name='', on_error_default=nil)
            @sub = Command.new(:get)
            @sub.set(:resource, resource)
            @sub.set(:resource_name, name)

            #allow command to ignore erroneous options
            def @sub.sanitize(args)
                ['get', @resource.to_s, @resource_name].concat(format_options(args))
            end

            if on_error_default
                @sub.set(:error_default, on_error_default)
                def @sub.format_err(runner)
                  LOGGER.debug("Returning default '#{@error_default}' as requested")
                  @error_default
                end
            end

            self
        end
    end

    module Create
        def create(kind, name)
            @sub = Command.new(:create)
            @sub.set(:kind, kind)
            @sub.set(:resource_name, name)

            def @sub.sanitize(args)
                ['create', @kind, @resource_name].concat(format_options(args))
            end
            self
        end
    end

    module Delete
        def delete(kind, name)
            @sub = Command.new(:delete)
            @sub.set(:kind, kind)
            @sub.set(:resource_name, name)

            def @sub.sanitize(args)
                ['delete', @kind, @resource_name].concat(format_options(args))
            end
            self
        end
    end

    module WhoAmI
        def whoami
            @sub = Command.new(:whoami)
            def @sub.sanitize(args)
                ['whoami'].concat(format_options(args))
            end
            def @sub.format_output(output, args)
                output.stdout.strip
            end
            self
        end
    end

    module Login
        def login(url)
            @sub = Command.new(:login)
            @sub.set(:url, url)
            @sub.arg('--insecure-skip-tls-verify',nil)

            def @sub.sanitize(args)
                ['login', @url].concat(format_options(args))
            end

            def @sub.username(username)
                @sub.set('--username', "'#{username}'")
               self
            end

            self
        end
    end

    module Logs
        def logs(pod)
            @sub = Command.new(:logs)
            @sub.set(:pod, pod)

            def @sub.sanitize(args)
               kind = @command == :latest ? '' : @kind
               ['logs', @pod].concat(format_options(args))
            end

            self
        end

    end

    module NewApp
        def new_app(image_tag)
          @sub = Command.new('new-app')
          @sub.set(:image_tag, image_tag)

          def @sub.sanitize(args)
              ['new-app', @image_tag].concat(format_options(args))
          end
          self
        end
    end

    module NewProject
        def new_project(proj_name)
          @sub = Command.new('new-project')
          @sub.set(:proj_name, proj_name)

          def @sub.sanitize(args)
              ['new-project', @proj_name].concat(format_options(args))
          end
          self
        end
    end

    module Rollout
        def rollout(command, kind, name)
            @sub = Command.new(:rollout)
            @sub.set(:command, command)
            @sub.set(:kind, kind)
            @sub.set(:resource_name, name)

            def @sub.sanitize(args)
               kind = @command == :latest ? '' : @kind
               ['rollout', @command, kind, @resource_name].concat(format_options(args))
            end

            def @sub.format_output(output, args)
                def output.in_progress?
                  self.include?("Waiting for rollout to finish")
                end
                output
            end

            self
        end
    end

    module ClusterRolePolicy
        def add_cluster_role_to_user(role, user)
          @sub = Command.new(:adm)
          @sub.set(:role, role)
          @sub.set(:user, user)

          def @sub.sanitize(args)
              ['adm', 'policy', 'add-cluster-role-to-user', @role, "'#{@user}'"].concat(format_options(args))
          end
          self
        end
    end

    module RolePolicy
        def add_role_to_user(role, user)
          @sub = Command.new(:policy)
          @sub.set(:role, role)
          @sub.set(:user, user)

          def @sub.sanitize(args)
              ['policy', 'add-role-to-user', @role, "'#{@user}'"].concat(format_options(args))
          end
          self
        end
    end

    module ServiceAccount
        def get_sa_token(name)
          @sub = Command.new(:serviceaccounts)
          @sub.set(:name, name)

          def @sub.sanitize(args)
              ['serviceaccounts','get-token', @name].concat(format_options(args))
          end
          self
        end
    end

    module Exec
        def exec(podname, pod_cmd, container: nil)
          @sub = Command.new(:exec)
          @sub.set(:podname, podname)
          @sub.set(:pod_cmd, pod_cmd)
          @sub.set(:container, container)
          def @sub.sanitize(args)
            cmd = ['exec', @podname].concat(format_options(args))
            cmd.concat(['-c', @container]) unless @container.nil?
            cmd.concat(['--', @pod_cmd])
          end

          def @sub.format_output(output, args)
              value = (output.stdout.nil? || output.stdout.length == 0) ? output.stderr : output.stdout
              LOGGER.debug "for cmd #{name} returning output: '#{value}'"
              value
          end

          self
        end
    end

    class OC

        include OpenshiftCliWrapper::Runner
        include ClusterRolePolicy
        include Create
        include Delete
        include Exec
        include Get
        include Login
        include Logs
        include NewApp
        include NewProject
        include Rollout 
        include RolePolicy
        include ServiceAccount
        include WhoAmI

        def do()
            begin
              if @sub.name == :login
                  unless @sub.args.key?('--username') && @sub.args.key?('--password')
                      raise OpenshiftCliWrapper::Errors::AuthorizationError.new('Must specify a username/password or token to login')
                  end
              end
              cmd = @sub.format('oc', @sub.args)
              output = execute(cmd)
              if output.success?
                  if @sub.respond_to?(:format_output)
                      output = @sub.format_output(output, @sub.args)
                  else
                      output = format_output(output, @sub.args)
                  end
                  return output
              else
                  if @sub.respond_to?(:format_err)
                      @sub.format_err(output.stderr)
                  else
                      LOGGER.error(output.stderr)
                      raise output.stderr
                  end
              end
            ensure
              @sub=nil
            end
        end

        def method_missing(method, *args, &block)
            method = method.to_s.sub('_','-') if method.to_s.include?('_')
            value =  args.length > 0 ? args[0] : nil
            @sub.arg("--#{method}", value)
            self
        end

        private

        def format_output(output, args)
          if ['yaml', 'json', :yaml, :json].include? args['--output']
              return OpenshiftCliWrapper::StructuredOutputFormatter.new.parse(args['--output'], output.stdout)
          end
          return output.stdout
        end
    end
end
