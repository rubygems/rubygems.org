Feature: Download Gems
  In order to get some awesome gems
  A developer
  Should be able to download some gems

  Scenario: Download a gem
    Given I am signed up and confirmed as "email@person.com/password"
    And I have a gem "sandworm" with version "1.0.0"
    And I have a gem "sandworm" with version "2.0.0"
    And I have an api key for "email@person.com/password"
    And I push the gem "sandworm-1.0.0.gem" with my api key
    And I push the gem "sandworm-2.0.0.gem" with my api key
    And the system processes jobs

    When I visit the gem page for "sandworm"
    Then I should see "0 total downloads"

    When I download the rubygem "sandworm" version "2.0.0" 3 times
    And the system processes jobs
    And I go to the homepage
    And I visit the gem page for "sandworm"
    Then I should see "3 total downloads"
    And I should see "3 downloads of this version"

    When I download the rubygem "sandworm" version "1.0.0" 2 times
    And the system processes jobs
    And I visit the gem page for "sandworm"
    Then I should see "5 total downloads"
    And I should see "3 downloads of this version"
    When I follow "1.0.0"
    Then I should see "5 total downloads"
    And I should see "2 downloads of this version"
