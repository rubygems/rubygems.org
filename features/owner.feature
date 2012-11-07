Feature: Manage owners
  In order to unclench the iron fist of my gemtatorship
  A gem owner
  Should be able to add and remove gem owners

  Background:
    Given the following users exist:
      | email              |
      | original@owner.org |
      | new@owner.org      |
    And the following rubygem exists:
      | name |
      | ogem |
    And the following ownership exists:
      | user                      | rubygem    |
      | email: original@owner.org | name: ogem |

  Scenario Outline: Gem owner user lists gem owners
    Given I sign in as "original@owner.org"
    And I have an API key for "original@owner.org/password"
    When I list the owners of gem "ogem" as "<format>" with my API key
    Then I should see "original@owner.org"
    And I should not see "new@owner.org"

    Examples:
      | format |
      | json   |
      | yaml   |

  Scenario: Gem owner adds another owner
    Given I sign in as "original@owner.org"
    And I have an API key for "original@owner.org/password"
    When I add the owner "new@owner.org" to the rubygem "ogem" with my API key
    And I list the owners of gem "ogem" with my API key
    Then I should see "original@owner.org"
    And I should see "new@owner.org"

  Scenario: Gem owner attempts to add another owner that does not exist
    Given I sign in as "original@owner.org"
    And I have an API key for "original@owner.org/password"
    When I add the owner "other@owner.org" to the rubygem "ogem" with my API key
    Then the response should contain "Owner could not be found."

  Scenario: Gem owner removes an owner
    Given I sign in as "original@owner.org"
    And I have an API key for "original@owner.org/password"
    And the following ownership exists:
      | user                 | rubygem    |
      | email: new@owner.org | name: ogem |
    When I remove the owner "new@owner.org" from the rubygem "ogem" with my API key
    And I list the owners of gem "ogem" with my API key
    Then I should see "original@owner.org"
    And I should not see "new@owner.org"

  Scenario: Gem owner attempts to remove ownership from a user that is not an owner
    Given I sign in as "original@owner.org"
    And I have an API key for "original@owner.org/password"
    When I remove the owner "new@owner.org" from the rubygem "ogem" with my API key
    Then the response should contain "Owner could not be found."

  Scenario: Gem owner removes himself when he is not the last owner
    Given I sign in as "original@owner.org"
    And I have an API key for "original@owner.org/password"
    And the following ownership exists:
      | user                 | rubygem    |
      | email: new@owner.org | name: ogem |
    When I remove the owner "original@owner.org" from the rubygem "ogem" with my API key
    Then the response should contain "Owner removed successfully."

  Scenario: Gem owner removes himself when he is the last owner
    Given I sign in as "original@owner.org"
    And I have an API key for "original@owner.org/password"
    When I remove the owner "original@owner.org" from the rubygem "ogem" with my API key
    Then the response should contain "Unable to remove owner."

  Scenario Outline: Attempt to manage a gem without the right permission
    Given I am signed up as "non@owner.org"
    And I have an API key for "non@owner.org/password"
    When I <action> with my API key
    Then the response should contain "You do not have permission to manage this gem."

    Examples:
      | action                                                        |
      | add the owner "new@owner.org" to the rubygem "ogem"           |
      | remove the owner "original@owner.org" from the rubygem "ogem" |
