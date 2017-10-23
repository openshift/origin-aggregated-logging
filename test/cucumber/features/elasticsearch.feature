#encoding: utf-8
Feature: The openshift-elasticsearch-plugin supports multitenancy

  @elasticsearch
  Scenario Outline: A user is granted permission to access their projects

    Given user <username> with the role of developer for project <project>
    And an application is generating logs in <project>
    And logs were collected for the <project> project
    When they search for <project> logs
    Then their access is not forbidden

    Examples:
      | username                                                     | project     | 
      | simpleusername                                               | devproject  |
      | foo@email.com                                                | devproject  |
      | CN=jdoe,OU=DL IT,OU=User Accounts,DC=example,DC=com          | devproject  |
      | test\username                                                | devproject  |
      | CN=Lastname\, Firstname,OU=Users,OU=TDBFG,DC=d2-tdbfg,DC=com | devproject  |
