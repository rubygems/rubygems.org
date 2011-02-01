Feature: Profile Feature
  In order to show off all my gems and such
  As a user
  I want to see a page with all of my gems

  Background:
    Given I am using HTTPS

  Scenario: Show Profile
    Given I have signed in with "jon@example.com/password"
    And a rubygem exists with a name of "sandworm"
    And the "sandworm" rubygem is owned by "jon@example.com"
    When I am on "jon@example.com" profile page
    Then I should see "sandworm"
	And I should not see "jon@example.com"

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
    Given I have signed in with "bob@example.com/password"
    And a user exists with an email of "jon@example.com"
    And a rubygem exists with a name of "sandworm"
    And the "sandworm" rubygem is owned by "jon@example.com"
    When I go to "jon@example.com" profile page
    Then I should see "sandworm"

  Scenario: Show other gems in my profile
    Given I have signed in with "jon@example.com/password"
    And the following rubygems exist for "jon@example.com":
      | name            | downloads |
      | the_trees       | 11        |
      | tom_sawyer      | 10        |
      | red_barchetta   | 9         |
      | yyz             | 8         |
      | limelight       | 7         |
      | the_camera_eye  | 6         |
      | witch_hunt      | 5         |
      | vital_signs     | 4         |
      | spirit_of_radio | 3         |
      | freewill        | 2         |
      | subdivisions    | 1         |
      | high_water      | 0         |
    When I am on "jon@example.com" profile page
    Then I should see download graphs for the following rubygems:
      | the_trees       |
      | tom_sawyer      |
      | red_barchetta   |
      | yyz             |
      | limelight       |
      | the_camera_eye  |
      | witch_hunt      |
      | vital_signs     |
      | spirit_of_radio |
      | freewill        |
    And I should not see download graphs for the following rubygems:
      | subdivisions |
      | high_water   |
