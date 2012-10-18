@javascript
Feature: Subscriptions
  In order to know about awesome gem updates
  A developer
  Should be able to subscribe to some gems

  Background:
    Given the following users exist:
      | email              |
      | original@owner.org |
      | new@owner.org      |
    And the following rubygem exists:
      | name |
      | OGem |
    And the following ownership exists:
      | user                      | rubygem    |
      | email: original@owner.org | name: OGem |
    And the following versions exist:
      | rubygem    | number |
      | name: OGem | 1.2.2  |
      | name: OGem | 1.2.3  |

  Scenario: Subscribe to a gem
    Given I am signed up as "non@owner.org"
    And I sign in as "non@owner.org"
    When I visit the gem page for "OGem"
    Then I should see "Subscribe"
    When I follow "Subscribe"
    Then I should see "Unsubscribe"
    And a subscription should exist for "non@owner.org" to "OGem"

  Scenario: Unsubscribe from a gem
    Given I am signed up as "non@owner.org"
    And "non@owner.org" has subscribed to "OGem"
    And I sign in as "non@owner.org"
    When I visit the gem page for "OGem"
    Then I should see "Unsubscribe"
    When I follow "Unsubscribe"
    Then I should see "Subscribe"
    And a subscription should not exist for "non@owner.org" to "OGem"
