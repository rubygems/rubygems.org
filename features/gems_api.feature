Feature: List gems API
  In order to see all the gems I work on
  A gem owner
  Should be able to list their gems

  Scenario: Gem owner user lists their gems
    Given I am signed up and confirmed as "original@owner.org/password"
    And I have an API key for "original@owner.org/password"
    And the following version exists:
      | rubygem     | number |
      | name: MyGem | 1.0.0  |
    And the following ownership exists:
      | rubygem     | user                      |
      | name: MyGem | email: original@owner.org |
    When I list the gems with my API key
    Then I should see "MyGem"
