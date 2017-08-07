Around do |scenario, block|
  master_url = if  ENV['PUBLIC_MASTER_URL']
    ENV['PUBLIC_MASTER_URL']
  else
    host=ENV['KUBERNETES_SERVICE_HOST']||'localhost'
    port=ENV['KUBERNETES_SERVICE_PORT']||'8443'
    "https://#{host}:#{port}"
  end

  create_world

  world.logger.debug(">>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<")
  world.logger.debug("SCENARIO: #{scenario.name} ##{scenario.location}")
  world.logger.debug(">>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<")
  
  world.namespace = 'logging'
  world.master_url = master_url
  world.login
  block.call
  world.browser.quit unless world.browser?
end

Around('@resetConfigMaps') do |scenario, block|
    world.logger.debug '@resetConfigMaps hook'
    raw = world.configmaps()
    raw.metadata.delete('creationTimestamp')
    raw.items.each { |cm| cm.metadata.delete('creationTimestamp') }
    block.call
    configs = world.dump_temp_yaml(raw)
    world.oc.delete(:configmaps,'').all().do()
    world.oc.create('','').filename(configs.path).do()
end

Before do |scenario| 
   @step ||= 0
   step = scenario.test_steps[@step]
   world.logger.debug(">>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<")
   world.logger.debug(">>>>>>>##{step.location}   #{step.name}")
   world.logger.debug(">>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<")
   @step += 1
end
