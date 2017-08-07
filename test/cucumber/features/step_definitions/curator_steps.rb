Given(/^the curator configuration has a project named (.*)$/) do |project|
    conf = dump_temp_yaml({
        "#{project}" => {
            'delete' => {
                'days' => 1
            }
        }
    })
    @dc = world.deployment_config('logging-curator')
    unless @dc.spec.template.spec.volumes.select{|v| v.key?('configMap')}.empty?
        world.delete(:configmap, 'logging-curator')
        world.create(:configmap, 'logging-curator', from_file: "config.yaml=#{conf.path}")
    else
      fail('found an unexpected condition')
    end
end

When(/^the curator pod is deployed$/) do
  latest = @dc.status.latestVersion
  @currentVersion = latest + 1
  if world.deployment_config('logging-curator').status.latestVersion < latest + 1
    world.rollout_latest(:deploymentconfig, 'logging-curator')
    expired = loop_maximum(40) do
        pods = world.pods(selector: "component=curator,deployment=logging-curator-#{@currentVersion}")
        pods.items.empty?
    end
    fail('Timed out waiting for the pod to start') if expired
  end
  
end

Then(/^it must generate the log error "(.*)"$/) do |message|
  expired = loop_maximum(40.0) do
    @curator_pods = world.pods(selector: "component=curator,deployment=logging-curator-#{@currentVersion}")
    @state = @curator_pods.items[0].status.containerStatuses[0].state
    (['running', 'terminated'] & @state.keys).empty? #continue to loop if the intersection is empty
  end
  
  fail('Timed out waiting for the pod to get to a usable state') if expired
  world.logger.debug("state: #{@state}")

  logs = ''
  expired = loop_maximum(10.0) do
    logs = world.logs(@curator_pods.items[0].metadata.name)
    !logs.include?(message) 
  end
  fail("Did not see expected message within the time expected") if expired
  fail("The expected message was not found in the curator logs:\n>>LOG START<<\n#{logs}\n>>LOG STOP<<\n")  unless logs.include?(message) 
end
