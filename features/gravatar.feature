Feature: Gravatar
  In order to have avatars of users around the site
  A user
  Should be able see users' gravatars where relevant

  Scenario: User is not signed in
    When I go to the homepage
    Then I should not see my gravatar

  Scenario: User is signed in
    Given I am using HTTPS
    And I have signed in with "email@person.com/password"
    When I go to the homepage
    Then I should see my gravatar
