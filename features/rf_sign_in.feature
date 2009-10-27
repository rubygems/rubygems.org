Feature: RubyForge legacy sign in
  In order to make the transition from RubyForge to GemCutter
  A user
  Should be able to sign in with their RubyForge credentials
  And automatically be given an account

    Scenario: RubyForge user has never logged on to GemCutter
      Given no user exists with an email of "email@person.com"
      And no RubyForge user exists with an email of "email@person.com"
      And a RubyForge user signs in with "email@person.com/password"
      Then I should see "Signed in"
      And I should be signed in
      And a confirmed user with an email of "email@person.com" exists
      And no RubyForge user exists with an email of "email@person.com"

#   Scenario: RubyForge user logs on with wrong password
#      Given no user exists with an email of "email@person.com"
#      And a RubyForge user exists with an email of "email@person.com"
#      When I go to the sign in page
#      And I sign in as "email@person.com/badpassword"
#      Then I should see "Bad email or password"
#      And I should be signed out
#      And no user exists with an email of "email@person.com"
