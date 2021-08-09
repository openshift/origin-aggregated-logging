---
name:  Bug Report
about: Create a report to help us improve. If you have questions about ES plugin on kubernetes, please direct these to https://discuss.kubernetes.io/ before sumbit kubernetes related issue.

---

(check apply)
- [ ] read [the contribution guideline](https://github.com/uken/fluent-plugin-elasticsearch/blob/master/CONTRIBUTING.md)
- [ ] (optional) already reported 3rd party upstream repository or mailing list if you use k8s addon or helm charts.

#### Problem

...

#### Steps to replicate

Either clone and modify https://gist.github.com/pitr/9a518e840db58f435911

**OR**

Provide example config and message

#### Expected Behavior or What you need to ask

...

#### Using Fluentd and ES plugin versions

* OS version
* Bare Metal or within Docker or Kubernetes or others?
* Fluentd v0.12 or v0.14/v1.0
  * paste result of ``fluentd --version`` or ``td-agent --version``
* ES plugin 3.x.y/2.x.y or 1.x.y
  * paste boot log of fluentd or td-agent
  * paste result of ``fluent-gem list``, ``td-agent-gem list`` or your Gemfile.lock
* ES version (optional)
* ES template(s) (optional)
