Feature: Edit Profile
  In order to keep their information up-to-date
  A user
  Should be able to edit their profile

  Scenario: Edit Handle
    Given I am using HTTPS
    And I have signed in with "john@example.com/password"
    And my handle is "johndoe"
    And I am on my edit profile page
    When I fill in "Handle" with "john_doe"
    And I press "Update"
    Then I should see my new "Handle"

  Scenario: Update with existing handle
    Given I have signed in with "janedoe@example.com/password"
    And my handle is "some_doe"
    And I sign out
    And I have signed in with "johndoe@example.com/password"
    And my handle is "john_doe"
    And I am on my edit profile page
    When I fill in "Handle" with "some_doe"
    And I press "Update"
    Then I should see "Handle has already been taken"
