Feature: Edit Profile
  In order to keep their information up-to-date
  A user
  Should be able to edit their profile

  @wip
  Scenario: Edit Handle
    Given I have signed in with "john@example.com/password"
    And my handle is "johndoe"
    And I am on my profile page

    When I follow "Edit"
    And I fill in "Handle" with "john"
    And I press "Update"

    Then I should see my new "Handle"
