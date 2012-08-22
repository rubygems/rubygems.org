Feature: List gems API
  In order to see all the gems I work on
  A gem owner
  Should be able to list their gems

  Scenario: Anonymous user lists gems for owner
    Given the following user exists:
      | email            | handle     |
      | user@example.com | myhandle |
    And the following version exists:
      | rubygem    | number |
      | name: agem | 1.0.0 |
    And the following ownership exists:
      | rubygem    | user                    |
      | name: agem | email: user@example.com |
      | name: bgem | |
    When I list the gems for owner "myhandle"
    Then I should see "agem"
    And I should not see "bgem"

  Scenario: Anonymous user lists gems for unknown user
    When I list the gems for owner "nobody"
    Then I should see "Owner could not be found."

  Scenario: Gem owner user lists their gems
    Given I am signed up as "original@owner.org"
    And I have an API key for "original@owner.org/password"
    And the following version exists:
      | rubygem     | number |
      | name: mygem | 1.0.0  |
    And the following ownership exists:
      | rubygem     | user                      |
      | name: mygem | email: original@owner.org |
    When I list the gems with my API key
    Then I should see "mygem"
