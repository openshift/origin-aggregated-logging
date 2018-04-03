#encoding: utf-8
Feature: The openshift-elasticsearch-plugin the Kibana index
  and Kibana UI objects

  #Scenario Outline: A user's kibana index is only seeded once
  @kibana
  Scenario: A user's kibana index is only seeded once with index
    mappings for the indices that are visible to them.

        #Given a user with the role of<role>
    Given a user with the role of operations
    And the user has never used Kibana
    #    And log were collected for the <project> project
    And logs were collected for the operations project
    And they log into Kibana
    #And refresh <project> index pattern field list
    And refresh operations index pattern field list
    When they log into Kibana again
    Then the index mapping fields should remain unchanged

    #    Examples:
    #  | role       | project    |
    #  | operations | operations |
    #   #| developer  | myproject |

  @kibana
  Scenario: The .all alias references all indices

    Given a user with the role of operations
    And the .all alias initially does not exist
    And logs were collected for the openshift-logging project
    When they log into Kibana
    Then the .all alias should alias indices: operations, openshift-logging
