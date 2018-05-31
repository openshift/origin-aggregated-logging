Given(/^a user with the role of (.*)$/) do |role|
    world.context[:role] = role
    if 'operations'.eql?(role) then
        # add step to grant cluster-admin from system:admin
        # need access to the admin.kubeconfig
        world.grant_cluster_admin_to('admin')
    end
end

Given(/^user (.*) with the role of (.*) for project (.*)$/) do | user, role, project_name|
    world.logger.debug("Using user:#{user} role:#{role} project:#{project_name}")
    world.context[:role] = role
    token = world.login(world.master_url, username: user).token
    admin = world.admin_user.token
    project = world.project(name: project_name, token: admin, not_found: {})
    if project.empty?
      world.new_project(project_name, token: admin)
      sleep(1.0)
    end
    world.grant_admin_to(user, project_name)
end
