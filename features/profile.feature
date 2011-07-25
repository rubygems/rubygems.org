Feature: Profile Feature
  In order to show off all my gems and such
  As a user
  I want to see a page with all of my gems

  Background:
    Given I have signed in with "jon@example.com/password"
    And the following version exists:
      | rubygem        | number |
      | name: sandworm | 2.0.0  |
    And the following ownership exists:
      | rubygem        | user                   |
      | name: sandworm | email: jon@example.com |

  Scenario: Show profile
    When I am on "jon@example.com" profile page
    Then I should see "sandworm"
    And I should not see "jon@example.com"

  Scenario: Show downloads for my gems in my profile
    Given I download the rubygem "sandworm" version "2.0.0" 3 times
    When I am on "jon@example.com" profile page
    Then I should see "sandworm"
    And I should see "3 today"

  Scenario: View another user's profile
    Given I have signed in with "bob@example.com/password"
    When I go to "jon@example.com" profile page
    Then I should see "sandworm"

  Scenario: Show other gems in my profile
    Given the following rubygems exist for "jon@example.com":
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
