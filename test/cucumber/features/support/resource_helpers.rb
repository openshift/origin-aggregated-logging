module ResourceHelpers
    
  def create(kind, name, from_file: '')
     @oc.create(kind, name)
        .namespace(@namespace)
        .token(@token)
        .from_file(from_file)
        .do()
  end

  def delete(kind, name)
     @oc.delete(kind, name)
        .namespace(@namespace)
        .token(@token)
        .do()
  end

  def configmaps
    @oc.get(:configmaps,'')
        .namespace(@namespace)
        .output('yaml')
        .token(@token)
        .do()
  end

  def deployment_config(name, token: @token, namespace: @namespace)
    list = @oc.get(:dc, name)
        .namespace(namespace)
        .output('yaml')
        .token(token)
        .do()
    return list unless name.empty?
    raise "Unable to find deploymentconfig named #{name}" if list.items.empty?
    list.items[0]
  end

  def logs(name, token: nil, namespace: nil)
     token = @token if token.nil?
     namespace = @namespace if namespace.nil?
     @oc.logs(name)
        .namespace(namespace)
        .token(token)
        .do()
  end

  def route(name: '', selector: '')
     @oc.get(:route, name)
        .selector("#{selector}")
        .namespace(@namespace)
        .output('yaml')
        .token(@token)
        .do()
  end

  def project(name: '', token:nil, not_found: nil)
     @oc.get(:project, name, not_found)
        .output('yaml')
        .token(token)
        .do()
  end

  def new_project(name, token:nil)
     @oc.new_project(name)
        .token(token)
        .do()
  end

  def new_app(image, namespace, token:nil)
     @oc.new_app(image)
        .namespace(namespace)
        .token(token)
        .do()
  end
  
  def service(name, token:nil, namespace: nil)
     token = @token if token.nil?
     namespace = @namespace if namespace.nil?
     @oc.get(:services, name)
        .namespace(namespace)
        .output('yaml')
        .token(token)
        .do()
  end

  # retrieve a pod or list by name or label.
  def pod(name: '', selector: '', token:nil, namespace: nil)
     token = @token if token.nil?
     namespace = @namespace if namespace.nil?
     @oc.get(:pods, name)
        .selector("#{selector}")
        .namespace(namespace)
        .output('yaml')
        .token(token)
        .do()
  end
  alias_method :pods, :pod

  def rollout_latest(kind, name)
      status = @oc.rollout(:status, kind, name)
        .namespace(@namespace)
        .token(@token)
        .watch(false)
        .do()
      unless status.in_progress?
          @oc.rollout(:latest, kind, name)
            .namespace(@namespace)
            .token(@token)
            .do()
      end
  end

end
