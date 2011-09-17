Feature: Sign up with handle
  In order to get access to protected sections of the site
  A user
  Should be able to sign up with handle

  Scenario: User signs up with no handle
    When I go to the sign up page
    And I fill in "Email" with "email@person.com"
    And I fill in "Password" with "password"
    And I press "Sign up"
    Then I should see error messages

  Scenario: User signs up with invalid handle
    When I go to the sign up page
    And I fill in "Email" with "email@person.com"
    And I fill in "Handle" with "thisusernameiswaytoolongseriouslywaytoolong"
    And I fill in "Password" with "password"
    And I press "Sign up"
    Then I should see an error message

  Scenario: User signs up with valid data
    When I go to the sign up page
    And I fill in "Email" with "email@person.com"
    And I fill in "Handle" with "validhandledude"
    And I fill in "Password" with "password"
    And I press "Sign up"
    Then I should be signed in
