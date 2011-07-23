Feature: Sign up
  In order to get access to protected sections of the site
  A user
  Should be able to sign up

    Scenario: User signs up with invalid email
      When I go to the sign up page
      And I fill in "Email" with "invalidemail"
      And I fill in "Password" with "password"
      And I fill in "Confirm password" with ""
      And I press "Sign Up"
      Then I should see error messages

    Scenario: User signs up with an already registered email
      Given I signed up with "email@person.com/password"
      When I go to the sign up page
      And I fill in "Email" with "email@person.com"
      And I fill in "Password" with "password"
      And I fill in "Confirm password" with ""
      And I press "Sign Up"
      Then I should see error messages

    Scenario: User signs up with no handle
      When I go to the sign up page
      And I fill in "Email" with "email@person.com"
      And I fill in "Password" with "password"
      And I fill in "Confirm password" with ""
      And I press "Sign Up"
      Then I should see error messages

    Scenario: User signs up with invalid handle
      When I go to the sign up page
      And I fill in "Email" with "email@person.com"
      And I fill in "Handle" with "thisusernameiswaytoolongseriouslywaytoolong"
      And I fill in "Password" with "password"
      And I fill in "Confirm password" with ""
      And I press "Sign Up"
      Then I should see error messages

    Scenario: User signs up with valid data
      When I go to the sign up page
      And I fill in "Email" with "email@person.com"
      And I fill in "Handle" with "validhandledude"
      And I fill in "Password" with "password"
      And I fill in "Confirm password" with "password"
      And I press "Sign Up"
      Then I should see "instructions for confirming"
      And a confirmation message should be sent to "email@person.com"

    Scenario: User confirms his account
      Given I signed up with "email@person.com/password"
      When I follow the confirmation link sent to "email@person.com"
      Then I should see "Confirmed email and signed in"
      And I should be signed in

    Scenario: Signed in user clicks confirmation link again
      Given I signed up with "email@person.com/password"
      When I follow the confirmation link sent to "email@person.com"
      Then I should be signed in
      When I follow the confirmation link sent to "email@person.com"
      Then I should see "Confirmed email and signed in"
      And I should be signed in

    Scenario: Signed out user clicks confirmation link again
      Given I signed up with "email@person.com/password"
      When I follow the confirmation link sent to "email@person.com"
      Then I should be signed in
      When I sign out
      And I follow the confirmation link sent to "email@person.com"
      Then I should see "Already confirmed email. Please sign in."
      And I should be signed out

