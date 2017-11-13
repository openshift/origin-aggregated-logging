# Re architect origin-aggregated-logging to use updated API objects and Templates to install

## Why?

Currently when we develop features or make changes that require configuration
updates as well as updates to our images we must coordinate those changes in two
repositories which can lead to things being out of sync or missed.

We should also take the time to evaluate how we deploy/configure the logging
stack and incorporate newer API objects where able, such as using Stateful Sets
to deploy Elasticsearch instead of Deployment Configs.

The installation restructure is based on the following proposal in the openshift-ansible
repository: https://github.com/openshift/openshift-ansible/pull/5826.

## How?

Taking from our experiences with supporting operations and customers, we should
be sure to incorporate those gotchas while minimizing the number of hacky
approaches we've included over releases.

We will want to create APB ("Ansible Playbook Bundles" [see references]) so we
can deliver a versioned container that will contain configurations for a specific
release and bundle that with a specific image version of our components.

An APB can best be thought of as a containerized playbook execution. Within the
container we would still maintain our roles and a playbook to install and uninstall
(called "provision" and "deprovision" within the APB naming scheme) our components.

We can create templates that allow granular deployment options (e.g.
how do we deploy Elasticsearch with stateful sets so that we can have different
zones and some be masters) while still maintaining the fewest number of template
files to keep our role simple.

Once the template files are created the logging role(s) will need to be updated
to consume and process these template files in a specific order and provide
parameters when appropriate.

I think we could also use this time to remove the openshift_logging role, instead
making it a playbook that would call the different component roles, and leverage
the configuration structure that Anton has been working on to have a very
customizable aggregated logging installation.

The added benefit of using the APB model is that we could potentially install
the logging stack using the Service Catalog on an existing cluster instead of
relying solely on the Ansible installer.

## Proposal

Update the deployment pattern for the logging stack to use APBs and OCP templates,
update our openshift-ansible role to kick off our APB container install/uninstall
while using these templates for deploying and configuring a complete logging
solution using newer API objects. We would maintain our APB within this repository,
similar to what we had done previously with the deployer pod.

# Limitations

There will be a lot of moving pieces with this and we likely will not be able
to do a simple upgrade going from Elasticsearch using deployment configs to
stateful sets. We will need to figure out a migration strategy and document
and test this. This may be complicated by the moving to ES 5.x.

# Additional considerations

We should also investigate the reintroduction of Image Streams for our
components to simplify updating images and ensuring we have the latest version
without needing to `docker pull` from each node where a logging component is
deployed.

## References
* https://github.com/openshift/openshift-ansible/blob/master/roles/template_service_broker/
* https://github.com/ansibleplaybookbundle/manageiq-apb
* https://github.com/ansibleplaybookbundle/ansible-playbook-bundle
* https://github.com/openshift/openshift-ansible/pull/5826
