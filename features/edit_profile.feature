Feature: Edit Profile
  In order to keep their information up-to-date
  A user
  Should be able to edit their profile

  Scenario: Edit Handle
    Given I have signed in with "john@example.com"
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
    And I have signed in with "johndoe@example.com"
    And I am on my edit profile page
    When I fill in "Handle" with "some_doe"
    And I press "Update"
    Then I should see "Handle has already been taken"

  Scenario: Turn off showing email for user
    Given I have signed in with "testing@example.com"
    And I am on "testing@example.com" profile page
    Then I should see "email"
    And I am on my edit profile page
    When I check "user_hide_email"
    And I press "Update"
    When I go to "testing@example.com" profile page
    Then I should not see "email"