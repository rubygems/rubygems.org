Feature: Yank Listing

  Scenario: Yanked gem is hidden from listing
    Given I am signed up and confirmed as "email@person.com/password"
    And I have a gem "RGem" with version "1.2.2"
    And I have a gem "RGem" with version "1.2.3"
    And I have an api key for "email@person.com/password"
    And I've already pushed the gem "RGem-1.2.2.gem" with my api key
    And the gem "RGem" with version "1.2.2" has been indexed
    And I've already pushed the gem "RGem-1.2.3.gem" with my api key
    And the gem "RGem" with version "1.2.3" has been indexed
    When I yank the gem "RGem" version "1.2.3" with my api key
    And I go to the dashboard
    And I follow "RGem"
    Then I should not see "yanked"
