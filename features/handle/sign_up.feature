Feature: Sign up with handle
  In order to get access to protected sections of the site
  A user
  Should be able to sign up with handle

  Scenario: User signs up with no handle
    When I go to the sign up page
    And I fill in "Email" with "email@person.com"
    And I fill in "Password" with "password"
    And I fill in "Confirm password" with ""
    And I press "Sign up"
    Then I should see error messages

  Scenario: User signs up with invalid handle
    When I go to the sign up page
    And I fill in "Email" with "email@person.com"
    And I fill in "Handle" with "thisusernameiswaytoolongseriouslywaytoolong"
    And I fill in "Password" with "password"
    And I fill in "Confirm password" with ""
    And I press "Sign up"
    Then I should see error messages

  Scenario: User signs up with valid data
    When I go to the sign up page
    And I fill in "Email" with "email@person.com"
    And I fill in "Handle" with "validhandledude"
    And I fill in "Password" with "password"
    And I fill in "Confirm password" with "password"
    And I press "Sign up"
    Then I should see "instructions for confirming"
    And a confirmation message should be sent to "email@person.com"
