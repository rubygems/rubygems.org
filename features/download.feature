Feature: Download Gems
  In order to get some awesome gems
  A developer
  Should be able to download some gems

  Scenario: Download a gem
    Given I am signed up and confirmed as "email@person.com/password"
    And I have a gem "sandworm" with version "1.0.0"
    And I have a gem "sandworm" with version "2.0.0"
    And I have an API key for "email@person.com/password"
    And I push the gem "sandworm-1.0.0.gem" with my API key
    And I push the gem "sandworm-2.0.0.gem" with my API key
    And the system processes jobs

    When I visit the gem page for "sandworm"
    Then I should see "0 total downloads"

    When I download the rubygem "sandworm" version "2.0.0" 3 times
    And the system processes jobs
    And I visit the gem page for "sandworm"
    Then I should see "3 total downloads"
    And I should see "3 for this version"

    When I download the rubygem "sandworm" version "1.0.0" 2 times
    And the system processes jobs
    And I visit the gem page for "sandworm"
    Then I should see "5 total downloads"
    And I should see "3 for this version"
    When I follow "1.0.0"
    Then I should see "5 total downloads"
    And I should see "2 for this version"

    When I download the rubygem "sandworm" version "2.0.0" 1000 times
    And the system processes jobs
    And I visit the gem page for "sandworm"
    Then I should see "1,005 total downloads"
    And I should see "1,003 for this version"

  Scenario: Download a platform gem
    Given I am signed up and confirmed as "email@person.com/password"
    And I have a gem "crysknife" with version "1.0.0"
    And I have a gem "crysknife" with version "1.0.0" and platform "java"
    And I have an API key for "email@person.com/password"
    And I push the gem "crysknife-1.0.0.gem" with my API key
    And I push the gem "crysknife-1.0.0-java.gem" with my API key
    And the system processes jobs

    When I visit the gem page for "crysknife" version "1.0.0"
    Then I should see "0 total downloads"

    When I download the rubygem "crysknife" version "1.0.0" 3 times
    And the system processes jobs
    And I visit the gem page for "crysknife" version "1.0.0"
    Then I should see "3 total downloads"
    And I should see "3 for this version"

    When I download the rubygem "crysknife" version "1.0.0-java" 2 times
    And the system processes jobs
    And I visit the gem page for "crysknife" version "1.0.0-java"
    Then I should see "5 total downloads"
    And I should see "2 for this version"

  Scenario: Download a .gem file for a platform gem
    Given I am signed up and confirmed as "email@person.com/password"
    And I have a gem "andhapp" with version "1.1.1"
    And I have a gem "andhapp" with version "1.1.0"
    And I have an API key for "email@person.com/password"
    And I push the gem "andhapp-1.1.1.gem" with my API key
    And I push the gem "andhapp-1.1.0.gem" with my API key
    And the system processes jobs

    When I visit the gem page for "andhapp" version "1.1.1"
    Then I should see "0 total downloads"

    When I visit the gem page for "andhapp" version "1.1.1"
    And I download the rubygem "andhapp" version "1.1.1" 1 time
    And I visit the gem page for "andhapp"
    Then I should see "1 total downloads"
    And I should see "1 for this version"

    When I visit the gem page for "andhapp" version "1.1.0"
    And I download the rubygem "andhapp" version "1.1.0" 1 time
    And I visit the gem page for "andhapp"
    Then I should see "2 total downloads"
    And I should see "1 for this version"
