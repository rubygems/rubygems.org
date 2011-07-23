Feature: Edit Profile
  In order to keep their information up-to-date
  A user
  Should be able to edit their profile

  Background:
    Given I am using HTTPS

  Scenario: Edit Handle
    Given I have signed in with "john@example.com/password"
    And my handle is "johndoe"
    And I am on my edit profile page
    When I fill in "Handle" with "john_doe"
    And I press "Update"
    Then I should see "john_doe"
    And I should not see "johndoe"

  Scenario: Update with existing handle
    Given the following user exists:
      | email               | handle   |
      | janedoe@example.com | some_doe |
    And I have signed in with "johndoe@example.com/password"
    And I am on my edit profile page
    When I fill in "Handle" with "some_doe"
    And I press "Update"
    Then I should see "Handle has already been taken"
