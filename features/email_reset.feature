Feature: Email reset
  In order to still use my account after I've changed my email address
  A user
  Should be able to reset the email address associated with my account

  Background:
    Given I am using HTTPS
    And I have signed in with "email@person.com/password"

  Scenario: User resets email address
    Given I am on my edit profile page
    When I fill in "Email address" with "email@newperson.com"
    And I press "Update"
    Then an email entitled "Email address confirmation" should be sent to "email@newperson.com"
    And I should see "You will receive an email within the next few minutes."
    And I should be signed out

  Scenario: User tries to reset email with an invalid email address
    When I am on my edit profile page
    And I fill in "Email address" with "this is an invalid email address"
    And I press "Update"
    Then I should see error messages

  Scenario: User confirms new email address
    When I have reset my email address to "email@newperson.com"
    And I follow the confirmation link sent to "email@newperson.com"
    Then I should see "Confirmed email and signed in"
    And I should be signed in

  Scenario: User tries to sign in in after resetting email address without confirmation
    When I have reset my email address to "email@newperson.com"
    And I sign in as "email@newperson.com/password"
    Then I should see "Confirmation email will be resent."
    And an email entitled "Email address confirmation" should be sent to "email@newperson.com"

  Scenario: User signs in after resetting and confirming email address
    When I have reset my email address to "email@newperson.com"
    And I follow the confirmation link sent to "email@newperson.com"
    And I sign in as "email@newperson.com/password"
    Then I should not see "sign in"
