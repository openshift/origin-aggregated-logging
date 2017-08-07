#encoding: utf-8
@elasticsearch @authorization
Feature: The openshift-elasticsearch-plugin authorizes access to the logging cluster

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

  @prometheus @skip
  Scenario: Metrics are returned for a valid service account

    Given Elasticsearch exposes a Prometheus endpoint
    When scraping the service endpoint for Elasticsearch using the configured serviceaccount
    Then metrics are returned

  @prometheus @skip
  Scenario: Metrics are returned when scraping the pod endpoint using the service account

    Given Elasticsearch exposes a Prometheus endpoint
    When scraping the pod endpoint for Elasticsearch using the configured serviceaccount
    Then metrics are returned

  @prometheus @skip
  Scenario: Metrics are denied for non-service account token

    Given Elasticsearch exposes a Prometheus endpoint
    Given user developer with the role of developer for project devproject
    When scraping the service endpoint for Elasticsearch using the user's token
    Then metrics are not returned

  @prometheus @skip
  Scenario: Metrics are denied for non-service account token against pod endpoint

    Given Elasticsearch exposes a Prometheus endpoint
    Given user developer with the role of developer for project devproject
    When scraping the pod endpoint for Elasticsearch using the user's token
    Then metrics are not returned
