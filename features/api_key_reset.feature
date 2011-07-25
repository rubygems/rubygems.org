Feature: API key reset
  In order to protect my account if my API key becomes known
  A user
  Should be able to reset it

  Scenario: User sees existing key on their profile page
    Given I have signed in with "email@person.com/password"
    And I am on my edit profile page
    Then I should see my "API key"

  Scenario: User resets API key
    Given I have signed in with "email@person.com/password"
    And I am on my edit profile page
    When I press "Reset my API key"
    Then I should see my new "API key"
