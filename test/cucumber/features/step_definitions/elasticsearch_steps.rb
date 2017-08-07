Given(/^logs were collected for the (.*) project$/) do |project|
  token = world.admin_user.token
  es_pod = world.es_pod(token: token)
  index = project == 'operations' ? '.operations.*' : "project.#{project}.*"
  expired = loop_maximum(600, 2.0) do
    world.index_exists?(es_pod.metadata.name, index, token: token)
  end
  fail ("Indices for the #{project} project do not exist yet") if expired
end

Given(/^the (.*) alias initially does not exist$/) do |alias_name|
  es_pod = world.es_pod
  token = world.admin_user.token
  world.delete_from_es(es_pod.metadata.name, token, "_all/_alias/#{alias_name}")
end

Then(/^the (.*) alias should alias indices: (.*)$/) do |alias_name, projects|
  sleep(3) #allow time for 'create' ops to sync
  exp = projects.split(',').map { |p| p.strip }.sort
  token = world.admin_user.token
  es_pod = world.es_pod(token: token)
  indices = world.query_from_es(es_pod.metadata.name, token, "_all/_alias/#{alias_name}") 
  re = /^(?<prefix>project)?\.(?<project>[^.]*)(\..*)*$/
  indices = indices.keys.map do |e|
    md =  re.match(e)
    md[:prefix].nil? ? ".#{md[:project]}" : md[:project]
  end.compact.uniq.sort
  world.logger.debug("#{exp & indices}  == #{exp}")
  fail("Exp. the alias #{alias_name} to include: #{exp} but it references #{indices}") if exp & indices != exp
end

And(/^an index-pattern exists for (.*)$/) do |project|
  admin_user = world.admin_user
  username = admin_user[:username]
  kibana_index = ".kibana.#{Digest::SHA1.hexdigest(username)}"
  doc_id = if project == '.all'
               project
             elsif project == 'operations'
                 '.operations.*'
             else
                 "project.#{project}.*"
             end
  index = "#{kibana_index}/index-pattern/#{doc_id}"
  fail("The index-pattern did not exist for alias/project #{project}") unless world.index_exists?(world.es_pod.metadata.name, index)
end

And(/^index-patterns exist for projects: (.*)$/) do |projects|
  projects = projects.split(',').collect{|p| p.strip}.sort
  admin_user = world.admin_user
  username = admin_user[:username]
  kibana_index = ".kibana.#{Digest::SHA1.hexdigest(username)}"
  query = "#{kibana_index}/index-pattern/_search?fields=_id"
  response = world.query_from_es(world.es_pod.metadata.name, admin_user[:token], query)
  re = /^(?<prefix>project)?\.(?<project>[^.]*)(\..*)*$/
  found = response.hits.hits.collect do |d|
      md = re.match(d['_id'])
      md[:prefix].nil? ? ".#{md[:project]}" : md[:project]
  end.compact
  exp = Set.new(projects)
  act = Set.new(found)
  fail("Missing index-pattern(s) for alias/project(s): #{(exp - act).to_a}") unless exp.subset?(act)
end

Given(/^Elasticsearch exposes a Prometheus endpoint$/) do
   pod = world.es_pod
   container = pod.spec.containers.select{|c| 'elasticsearch'.eql?(c.name)}.first 
   env = container.env.select{|e| 'PROMETHEUS_USER'.eql?(e.name)}.first
   fail('The pod does not expose a Prometheus endpoint') if env.nil?
   sa = env.value
   world.logger.debug("Elasticsearch THEUS_USER: #{sa}") 
   world.context[:es_prometheus_user] = sa
end

When(/^scraping the (.*)endpoint for Elasticsearch using the configured serviceaccount$/) do |endpoint|
   sa = world.context[:es_prometheus_user]
   md = /^system:serviceaccount:(?<namespace>.*):(?<name>.*)$/.match(sa)
   token = world.oc.get_sa_token(md[:name]).namespace(md[:namespace]).do()
   headers = "-H 'Authorization: Bearer #{token}'"
   endpoint = if 'pod' == endpoint
              #  headers << " -H 'x-forwarded-user: #{sa}'"
                "#{world.es_pod(token: world.admin_user.token).status.podIP}:9200"
              else
              #  headers << " -H 'Authorization: Bearer #{token}'"
                'logging-es-prometheus'
              end
   cmd = "curl -kv https://#{endpoint}/_prometheus/metrics #{headers}"
   pod = world.kibana_pod
   world.context[:response] = world.oc.exec(pod.metadata.name, cmd)
     .namespace('logging')
     .container('kibana')
     .token(world.admin_user.token)
     .do()
end

When(/^scraping the (.*)endpoint for Elasticsearch using the user's token$/) do |endpoint|
   user = world.context[:user]
   token = user.token
   endpoint = if 'pod' == endpoint
                "#{world.es_pod(token: world.admin_user.token).status.podIP}:9200"
              else
                'logging-es-prometheus'
              end
   cmd = "curl -kv https://#{endpoint}/_prometheus/metrics -H 'Authorization: Bearer #{token}' -H 'x-forwarded-for: 127.0.0.1'"
   pod = world.kibana_pod(token: world.admin_user.token)
   world.context[:response] = world.oc.exec(pod.metadata.name, cmd)
     .namespace('logging')
     .container('kibana')
     .token(world.admin_user.token)
     .do()
end

Then(/^metrics are returned$/) do
    response = world.context[:response]
    unless /(.*TYPE es_indices.*)+/.match?(response)
      fail("Received an unsuccessful response: #{response}") 
    end
end
Then(/^metrics are not returned$/) do
    response = world.context[:response]
    if /(.*TYPE es_indices.*)+/.match?(response)
      fail("Received a successful response: #{response}") 
    end
end
