Feature: Sign in
  In order to get access to protected sections of the site
  A user
  Should be able to sign in

    Background:
      Given I am using HTTPS

    Scenario: User is not signed up
      When I go to the sign in page
      And I sign in as "email@person.com/password"
      Then I should see "Bad email or password"
      And I should be signed out

    Scenario: User is not confirmed
      Given I signed up with "email@person.com/password"
      When I go to the sign in page
      And I sign in as "email@person.com/password"
      Then I should see "User has not confirmed email"
      And I should be signed out

    Scenario: User enters wrong password
      Given I am signed up and confirmed as "email@person.com/password"
      When I go to the sign in page
      And I sign in as "email@person.com/wrongpassword"
      Then I should see "Bad email or password"
      And I should be signed out

    Scenario: User signs in successfully with email
      Given I am signed up and confirmed as "email@person.com/password"
      When I go to the sign in page
      And I sign in as "email@person.com/password"
      Then I should see "Signed in"
      And I should be signed in
      When I return next time
      Then I should be signed in

    Scenario: User signs in successfully with handle
      Given I am signed up and confirmed as "email@person.com/password"
      And my handle is "signinnow"
      When I go to the sign in page
      And I sign in as "signinnow/password"
      Then I should see "Signed in"
      And I should be signed in
      When I return next time
      Then I should be signed in
