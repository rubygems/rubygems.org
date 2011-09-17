Feature: Email change
  In order to still use my account after I've changed my email address
  A user
  Should be able to change the email address associated with my account

  Background:
    Given I have signed in with "email@person.com"

  Scenario: User changes their email to a new address
    When I have changed my email address to "email@newperson.com"
    And I sign out
    When I sign in as "email@newperson.com"
    Then I should not see "sign in"

  Scenario: User tries to change their email to an invalid email address
    When I am on my edit profile page
    And I fill in "Email address" with "this is an invalid email address"
    And I press "Update"
    Then I should see an error message
