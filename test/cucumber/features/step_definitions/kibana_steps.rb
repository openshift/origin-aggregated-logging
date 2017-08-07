When(/^they search for (.*) logs(?:.?without using their)?.?(.*)?$/) do |project_name, auth_attribute|
  admin = world.admin_user
  user = world.context[:user]
  index = "project.#{project_name}.*"
  es_pod = world.es_pod(token: admin.token)
  fail("The index #{index} does not exist so search will fail") unless world.index_exists?(es_pod.metadata.name, index, token: admin.token)
  kibana_pod = world.kibana_pod(token: admin.token)
  response = world.doc_count_from_kibana(kibana_pod, 
               user.username, 
               admin.token, 
               index, 
               bearer_token: user.token,
               use_certs: false,
               omit_header: auth_attribute
           )
  world.context[:response] = response
end

Then(/^their access is (.*)$/) do |status|
  response = world.context[:response]
  # assume failure only when response has a status.
  # 200 response will have a result.
  case status
  when 'unauthorized'
      fail("Exp response to be an error response but was successful: '#{response}'") unless response.respond_to?(:key?) && response.key?('error')
    fail("Exp response to be unauthorized (401) but was was: '#{response.error.status}'") unless response.error.status == 401
  when 'authorized'
  when 'not forbidden'
    fail("Exp a user to be allowed access to the resource but response was: '#{response}'") if response.key?('error')
  else
    fail("step definition does not handle the status of #{status}")
  end
end

Given(/^they log into Kibana$/) do
    route = "https://#{world.route(name: 'logging-kibana').spec.host}"
    world.logger.debug("Kibana route: #{route}")
    b = world.browser
    b.goto route
    fail("Exp. to be at the login page but was: #{b.title }") unless b.title.start_with?('Login')

    admin_user = world.admin_user
    b.text_field(id: 'inputUsername').set(admin_user[:username])
    b.text_field(id: 'inputPassword').set('abc123')
    b.button(class: 'btn-primary').click
    b.a(text: /^.*Discover.*?$/).wait_until(timeout: 30, message: 'Failed to login to Kibana or page didnt load',&:present?)
end

Given(/^the user has never used Kibana$/) do
  es_pod = world.pod(selector: 'logging-infra=elasticsearch').items.first
  admin_user = world.admin_user
  username = admin_user[:username]
  token = admin_user[:token]
  world.delete_from_es(es_pod.metadata.name, token, ".kibana.#{Digest::SHA1.hexdigest(username)}")
  sleep(5.0)
end

When(/^they log into Kibana again$/) do
   b = world.browser
   logout = b.a(text: 'Log out')
   if logout.exists?
     logout.click 
     fail ("Exp. to be returned to Openshift webconsole but it was #{b.title}") unless b.title.start_with?('OpenShift')
   end
   step 'they log into Kibana'
end

Given(/^refresh (.*) index pattern field list$/) do | project_name |
  b = world.browser
  fail("Exp. to be interacting with Kibana but was #{b.title}") unless b.title.start_with?('Kibana')

  
  admin_user = world.admin_user
  username = admin_user[:username]
  token = admin_user[:token]

  #get doc from Elastic
  kib = world.pod(selector: 'logging-infra=kibana').items.first
  project = world.project(name: project_name, token: token)
  id = "project.#{project_name}.#{project.metadata.uid}.*"
  result = world.get_index_mapping(kib, username, token, id)
  fail("Unable retrieve field list before refreshing: #{result}") unless result.docs.first.found
  world.context[:index_mapping_orig] = result

  b.link(text: 'Settings').click
  b.link(text: 'Indices').click
  b.span(text: id).click
  text = b.a(text: /^.*fields.*\(\d*\).*$/, class: 'ng-binding').text
  ui_fields_before = /^.*\((\d*)\).*$/.match(text)[1].to_i

  b.button(text: /^.*Reload field list.*$/).click
  b.alert.ok

  text = b.a(text: /^.*fields.*\(\d*\).*$/, class: 'ng-binding').wait_until(timeout: 5) do |f|
      f.text.to_i != ui_fields_before
  end.text
  ui_fields_after = /^.*\((\d*)\).*$/.match(text)[1].to_i

  world.logger.debug("UI fields before: #{ui_fields_before} after: #{ui_fields_after}")
  world.logger.debug("Exp. the UI to reflect a change in index mapping fields after refresh. before #{ui_fields_before} after: #{ui_fields_after} did refresh succeed? maybe after is truely the same") if ui_fields_before == ui_fields_after

  #get doc from Elastic
  result = world.get_index_mapping(kib, username, token, id)
  fail("Unable retrieve field list after refreshing: #{result}") unless result.docs.first.found
  world.context[:index_mapping_new] = result
  world.context[:index_mapping_id] = id
  refreshed = JSON.parse(world.context[:index_mapping_new].docs.first._source.fields)
  fail("Failed to write when refreshing field mappings. UI says #{ui_fields_after} but saved index says #{refreshed.length}") if refreshed.length != ui_fields_after
end

Then(/^the index mapping fields should remain unchanged$/) do
  admin_user = world.admin_user
  username = admin_user[:username]
  token = admin_user[:token]
  kib = world.pod(selector: 'logging-infra=kibana').items.first

  id = world.context[:index_mapping_id]
  reloaded = world.get_index_mapping(kib, username, token, id)
  fields = JSON.parse(reloaded.docs.first._source.fields)
  refreshed = JSON.parse(world.context[:index_mapping_new].docs.first._source.fields)
  fail("The index mapping fields changed from #{refreshed.length} to #{fields.length}") if fields.length != refreshed.length 
end


