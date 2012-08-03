Feature: Password reset with handle
  In order to sign in even if user forgot their password
  A user
  Should be able to reset it with handle

  Scenario: User is signed up and updates his password without having a handle
    Given I signed up with "email@example.com"
    And my handle is nil
    When I go to the password reset request page
    And I fill in "Email address" with "email@example.com"
    And I press "Reset password"
    Then a password reset message should be sent to "email@example.com"
    When I follow the password reset link sent to "email@example.com"
    And I update my password with "newpassword"
    Then I should be signed in
    When I sign out
    Then I should be signed out
    When I go to the sign in page
    And I fill in "Email" with "email@example.com"
    And I fill in "Password" with "newpassword"
    And I press "Sign in"
    Then I should be signed in
