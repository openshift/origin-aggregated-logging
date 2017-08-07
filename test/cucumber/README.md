# Behavior Driven Development (BDD)
BDD is a principle for testing by which a particular feature is
described in plain languange with the intention of making it more obvious
what is being tested under certain conditions.

# Set up

```
$ sudo bash
$ REMOVE_PACKAGES="ruby-devel wget gcc bzip2 make"  \
  INSTALL_PACKAGES="ruby firefox libffi xorg-x11-server-Xvfb" \
  yum -y $INSTALL_PACKAGES $REMOVE_PACKAGES
$ GEM_HOME=vendor gem install bundler --no-ri
$ GEM_HOME=vendor bundler install
```

Download and unarchive the following to `/usr/local/bin`:
* [Openshift client binary](https://github.com/openshift/origin/releases/download/v3.6.0/openshift-origin-client-tools-v3.6.0-c4dd4cf-linux-64bit.tar.gz)
* [Gecko Browser Driver](https://github.com/mozilla/geckodriver/releases/download/v0.19.0/geckodriver-v0.19.0-linux64.tar.gz)

# Running Tests
These tests are written with the following assumptions:

* An Openshift cluster was deployed prior to test execution
* Origin logging components were deployed prior to test execution
* A user named 'admin' was granted cluster-admin cluster role `oadm policy add-cluster-role-to-user cluster-admin admin`
* The test will try to reset the environment to the state when its done

```
$ GEM_HOME=vendor LOGLEVEL=info bundle exec cucumber
```

Sample out put from a succesful run:

```
#encoding: utf-8
Feature: Curator maintains the size of the Elasticsearch
  data store to ensure it does not grow larger then
  avaliable capacity.

  @resetConfigMaps
  Scenario Outline: An improper configuration errors and generates a log message. # features/curator.feature:7
    Given the curator configuration has a project named <project>                 # features/curator.feature:8
    When the curator pod is deployed                                              # features/curator.feature:9
    Then it must generate the log error "<message>"                               # features/curator.feature:10

    Examples:
      | project                                                                                                                                                 | message                                               |
      | -BOGUS^PROJECT^NAME                                                                                                                                     | The project name must match this regex                |
      | this-project-name-is-far-far-too-long-this-project-name-is-far-far-too-long-this-project-name-is-far-far-too-long-this-project-name-is-far-far-too-long | The project name length must be less than or equal to |

2 scenarios (2 passed)
6 steps (6 passed)
1m11.964s

```
# Environment Variables
| Variable | Desc | Values (Defaults in bold)|
|----------|------|--|
| `LOGLEVEL` | The loglevel to control output from the run | `info`, **`debug`**, `error`, `warn`|
| `HEADLESS` | Browser tests run headless or not           | `true`, **`false`**|
| `PUBLIC_MASTER_URL` | The api server url to use for the tests | **https://localhost:8443** |

# Running from a container
## Building the image
```
docker build -t logging-cucumber .
```
## Running the Tests

```
docker run -e PUBLIC_MASTER_URL=https://192.168.122.61:8443 -e LOGLEVEL=debug logging-cucumber
```

# Running and building from the cluster
The following will create resources on the cluster to support a job to run cucumber.  This job will produce typical cucumber output as described previously 
as well as a debug log that is dumped at the end of the run.

## Creating resources
```
oc process -f resources.yml | oc create -f -
```
## Building the image
```
oc start-build logging-cucumber
```
or
```
oc start-build logging-cucumber --from-dir=$REPO_ROOT
```
## Running the Tests
```
oc new-app logging-cucumber-job -e TAGS=@kibana
oc logs -f $JOBPOD
```
Environment Variables
| Variable | Desc | Values (Defaults in bold)|
|----------|------|--|
| `LOGLEVEL` | The loglevel to control output from the run | `info`, **`debug`**, `error`, `warn`|
| `TAGS`| The cucumber tags when filtering feature files ||
