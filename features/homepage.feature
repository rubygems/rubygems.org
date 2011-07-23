Feature: Homepage

  Scenario: Most downloaded gems for today
    Given I am signed up and confirmed as "email@person.com/password"
    And I have an api key for "email@person.com/password"
    And I have a gem "sandworm" with version "1.0.0"
    And I have a gem "sandworm" with version "2.0.0"
    And I have a gem "fireworm" with version "1.0.0"
    And I push the gem "sandworm-1.0.0.gem" with my api key
    And I push the gem "sandworm-2.0.0.gem" with my api key
    And I push the gem "fireworm-1.0.0.gem" with my api key

    When I am on the homepage
    Then I should see "No downloads today"

    Given I download the rubygem "sandworm" version "1.0.0" 5 times
    And I download the rubygem "sandworm" version "2.0.0" 10 times
    And I download the rubygem "fireworm" version "1.0.0" 20 times

    When I am on the homepage
    Then I should see the following most recent downloads:
      | fireworm-1.0.0 (20) |
      | sandworm-2.0.0 (10) |
      | sandworm-1.0.0 (5)  |
