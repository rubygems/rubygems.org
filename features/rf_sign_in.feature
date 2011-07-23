Feature: RubyForge legacy sign in
  In order to make the transition from RubyForge to GemCutter
  A user
  Should be able to sign in with their RubyForge credentials
  And automatically be given an account

  Background:
    Given I am using HTTPS

  Scenario: RubyForge user has never logged on to GemCutter
    Given I signed up with "email@person.com/randompw"
    And I have a RubyForge account with "email@person.com/rfpassword"
    And I sign in as "email@person.com/rfpassword"
    Then I should see "Signed in"
    And I should be signed in
    And my GemCutter password should be "rfpassword"
    And no RubyForge user exists with an email of "email@person.com"

  Scenario: RubyForge user logs on with wrong password
    Given I have a RubyForge account with "email@person.com/rfpassword"
    When I go to the sign in page
    And I sign in as "email@person.com/badpassword"
    Then I should see "Bad email or password"
    And I should be signed out
