And(/^an application is generating logs in (.*)$/) do | project_name|
  user = world.context[:user]
  pods = world.pods(selector: 'app=hello-openshift', token: user.token, namespace: project_name)
  if pods.items.empty? 
    world.new_app('openshift/hello-openshift', project_name, token: user.token)
    expired = loop_maximum(30) do
      pods = world.pods(selector: 'app=hello-openshift', token: user.token, namespace: project_name)
      pods.items.empty? || pods.items[0].status.phase != 'Running'
    end
    fail("Timed out waiting for the hello-openshift pod to start in #{project_name}") if expired
  end
  svc = world.service('hello-openshift', token: world.admin_user.token, namespace: project_name)
  cmd = ["curl", "-qk","#{svc.spec.clusterIP}:#{svc.spec.ports[0].port}"]
  result = world.oc.execute(cmd)
  logs = world.logs(pods.items[0].metadata.name, token: user.token, namespace: project_name)
  fail("The hello-openshift pod has not generated logs that can be collected") if logs.empty?
end
