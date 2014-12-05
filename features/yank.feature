Feature: Delete Gems
  In order to remove my botched release
  As a rubygem developer
  I want to delete gems from Gemcutter

  Scenario: User unyanks a gem with no indexed versions
    Given I am signed up as "email@person.com"
    And I have an API key for "email@person.com/password"
    And the following ownership exists:
      | rubygem    | user                    |
      | name: RGem | email: email@person.com |
    And the following versions exist:
      | rubygem    | number |
      | name: RGem | 1.2.3  |
    When I yank the gem "RGem" version "1.2.3" with my API key
    And I go to the dashboard
    And I go to the "RGem" rubygem page
    Then I should see "This gem has been yanked"

    When I unyank the gem "RGem" version "1.2.3" with my API key
    And I go to the dashboard
    And I follow "RGem"
    Then I should not see "This gem has been yanked"
