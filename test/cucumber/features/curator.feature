#encoding: utf-8
@skip
Feature: Curator maintains the size of the Elasticsearch
  data store to ensure it does not grow larger then
  avaliable capacity.

  @resetConfigMaps
  Scenario Outline: An improper configuration errors and generates a log message.
    Given the curator configuration has a project named <project>
    When the curator pod is deployed
    Then it must generate the log error "<message>"
    Examples:
      | project             | message                                |
      | -BOGUS^PROJECT^NAME | The project name must match this regex |
      | this-project-name-is-far-far-too-long-this-project-name-is-far-far-too-long-this-project-name-is-far-far-too-long-this-project-name-is-far-far-too-long | The project name length must be less than or equal to |
