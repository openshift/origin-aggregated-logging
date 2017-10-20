# Re architect origin-aggregated-logging to use updated API objects and Templates to install

## Why?

Currently when we develop features or make changes that require configuration
updates as well as updates to our images we must coordinate those changes in two
repositories which can lead to things being out of sync or missed.

We should also take the time to evaluate how we deploy/configure the logging
stack and incorporate newer API objects where able, such as using Stateful Sets
to deploy Elasticsearch instead of Deployment Configs.

## How?

Taking from our experiences with supporting operations and customers, we should
be sure to incorporate those gotchas while minimizing the number of hacky
approaches we've included over releases.

We will need to create templates that allow granular deployment options (e.g.
how do we deploy Elasticsearch with stateful sets so that we can have different
zones and some be masters) while still maintaining the fewest number of template
files to keep the role simple.

Once the template files are created the logging role(s) will need to be updated
to consume and process these template files in a specific order and provide
parameters when appropriate.

This would mirror work that was done for the Template Service Broker role [see
references].

## Proposal

Update the deployment pattern for the logging stack to use OCP templates and
update our openshift-ansible role to use these templates for deploying
and configuring a complete logging solution using newer API objects.

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

This would also be a good time to update the openshift-ansible role to ensure
that we have the latest release of image versions pulled down to the registry.

## References
* https://github.com/openshift/openshift-ansible/blob/master/roles/template_service_broker/
