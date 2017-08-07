#encoding: utf-8
@elasticsearch @authentication
Feature: The openshift-elasticsearch-plugin authenticates for the logging cluster

  Scenario Outline: Users are required to provide username and bearer token

    Given user test with the role of developer for project <project>
    And an application is generating logs in <project>
    And logs were collected for the <project> project
    And they search for <project> logs
    When they search for <project> logs without using their <auth_attribute>
    Then their access is <auth_result>

    Examples:
      | auth_attribute | project    | auth_result  |
      | token          | devproject | unauthorized |
      | username       | devproject | authorized   |
