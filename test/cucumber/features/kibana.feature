#encoding: utf-8
@kibana
Feature: The openshift-elasticsearch-plugin seeds the Kibana index
  and Kibana UI objects

  @browser
  Scenario Outline: A user's kibana index is only seeded once

    Given user <user> with the role of <role> for project <project>
    And the user has never used Kibana
    And logs were collected for the <project> project
    And they log into Kibana
    And refresh <project> index pattern field list
    When they log into Kibana again
    Then the index mapping fields should remain unchanged

    Examples:
      | user      | role       | project  |
      | admin     | operations | logging  |
      | developer | developer  | logging  |

  Scenario: The .all alias references all indices and
   index-patterns are created

    Given a user with the role of operations
    And the .all alias initially does not exist
    And logs were collected for the openshift-logging project
    When they log into Kibana
    Then the .all alias should alias indices: .operations, logging
    And index-patterns exist for projects: .all, .operations, openshift-logging
