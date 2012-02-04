@javascript
Feature: Subscription

  Background: 
    Given I have signed in with "bob@example.com"
    And the following rubygems exist:
      | name     |
      | sandworm |
    And the following versions exist:
      | rubygem        | number | platform    |
      | name: sandworm | 2.0.0  | ruby        |

  Scenario: User subscribes
    When I visit the gem page for "sandworm"
    Then I should see "Subscribe"
    When I follow "Subscribe"
    Then I should be subscribed to "sandworm"
    And I should see "Unsubscribe"

  Scenario: User unsubscribes
    Given the following subscriptions exist:
      | user                    | rubygem        |
      | email: bob@example.com  | name: sandworm |
    When I visit the gem page for "sandworm"
    Then I should see "Unsubscribe"
    When I follow "Unsubscribe"
    Then I should be unsubscribed to "sandworm"
    And I should see "Subscribe"
