Feature: Password reset with handle
  In order to sign in even if user forgot their password
  A user
  Should be able to reset it with handle

  Scenario: User is signed up and updates his password without having a handle
    Given I signed up with "email@person.com"
    And my handle is nil
    When I go to the password reset request page
    And I fill in "Email address" with "email@person.com"
    And I press "Reset password"
    Then a password reset message should be sent to "email@person.com"
    When I follow the password reset link sent to "email@person.com"
    And I update my password with "newpassword"
    Then I should be signed in
    When I sign out
    Then I should be signed out
    And I sign in as "email@person.com"
    Then I should be signed in
