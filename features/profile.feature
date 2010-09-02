Feature: Profile Feature
  In order to show off all my gems and such
  As a user
  I want to see a page with all of my gems

  Scenario: Show Profile
    Given I have signed in with "jon@example.com/password"
    And a rubygem exists with a name of "sandworm"
    And the "sandworm" rubygem is owned by "jon@example.com"
    When I am on "jon@example.com" profile page
    Then I should see "sandworm"

  Scenario: Show todays downloads for my gems in my profile
    Given I have signed in with "jon@example.com/password"
    And a rubygem exists with a name of "sandworm"
    And a version exists for the "sandworm" rubygem with a number of "2.0.0"
    And the "sandworm" rubygem is owned by "jon@example.com"
    And I download the rubygem "sandworm" version "2.0.0" 3 times
    When I am on "jon@example.com" profile page
    Then I should see "sandworm"
    And I should see "3 today"

  Scenario: Show total downloads for my gems in my profile
    Given I have signed in with "jon@example.com/password"
    And a rubygem exists with a name of "sandworm"
    And a version exists for the "sandworm" rubygem with a number of "2.0.0"
    And the "sandworm" rubygem is owned by "jon@example.com"
    And I download the rubygem "sandworm" version "2.0.0" 3 times
    When I am on "jon@example.com" profile page
    Then I should see "sandworm"
    And I should see "3 today"

  Scenario: Show Profile
    Given a user exists with an email of "jon@example.com"
    And a rubygem exists with a name of "sandworm"
    And the "sandworm" rubygem is owned by "jon@example.com"
    When I go to "jon@example.com" profile page
    Then I should see "sandworm"


