Feature: Sign in with handle
  In order to get access to protected sections of the site
  A user
  Should be able to sign in with handle

  Scenario: User signs in successfully with handle
    Given I am signed up as "email@person.com"
    And my handle is "signinnow"
    When I go to the sign in page
    And I sign in as "signinnow"
    Then I should be signed in
