Feature: Delete Gems
  In order to remove my botched release 
  As a rubygem developer
  I want to delete gems from Gemcutter
  
@wip
  Scenario: User yanks a gem
    Given I am signed up and confirmed as "email@person.com/password"
    And I have a gem "RGem" with version "1.2.2"
    And I have a gem "RGem" with version "1.2.3"
    And I have an api key for "email@person.com/password"
    And I've already pushed the gem "RGem-1.2.2.gem" with my api key
    And the gem "RGem" with version "1.2.2" has been indexed
    And I've already pushed the gem "RGem-1.2.3.gem" with my api key
    And the gem "RGem" with version "1.2.3" has been indexed
    When I yank the gem "RGem" version "1.2.3" with my api key
    And I go to the dashboard with my api key
    Then I should see "RGem"
    And I visit the gem page for "RGem" version "1.2.3"
    Then I should see "This gem has been yanked."
    And I visit the gem page for "RGem"
    Then I should see the version "1.2.2" featured

  Scenario: User yanks the last version of a gem
    Given I am signed up and confirmed as "old@owner.com/password"
    And I have a gem "RGem" with version "1.2.3"
    And I have an api key for "old@owner.com/password"
    And I've already pushed the gem "RGem-1.2.3.gem" with my api key
    And the gem "RGem" with version "1.2.3" has been indexed
    When I yank the gem "RGem" version "1.2.3" with my api key
    And I visit the gem page for "RGem"
    And I should see "This gem has been yanked."
    
    When I am signed up and confirmed as "new@owner.com/password"
    And I have a gem "RGem" with version "0.1.0"
    And I have an api key for "new@owner.com/password"
    When I push the gem "RGem-0.1.0.gem" with my api key
    And I visit the gem page for "RGem"
    Then I should see "RGem"
    And I should see "0.1.0"
    When I list the owners of gem "RGem" with my api key
    Then I should see "new@owner.com"
    And I should not see "old@owner.com"
    
  Scenario: User who is not owner attempts to yank a gem
    Given I am signed up and confirmed as "non@owner.org/password"
    And a user exists with an email of "the@owner.org"
    And I have an api key for "non@owner.org/password"
    And a rubygem exists with a name of "RGem"
    And a version exists for the "RGem" rubygem with a number of "1.2.3"
    And the "RGem" rubygem is owned by "the@owner.org"
    And the gem "RGem" with version "1.2.3" has been indexed
    When I attempt to yank the gem "RGem" version "1.2.3" with my api key
    Then I should see "You do not have permission to yank this gem."
    
  Scenario: User attempts to yank a nonexistent version of a gem
    Given I am signed up and confirmed as "the@owner.com/password"
    And I have a gem "RGem" with version "1.2.3"
    And I have an api key for "the@owner.com/password"
    And I've already pushed the gem "RGem-1.2.3.gem" with my api key
    And the gem "RGem" with version "1.2.3" has been indexed
    When I attempt to yank the gem "RGem" version "1.2.4" with my api key
    Then I should see "The version 1.2.4 does not exist."
  
  Scenario: User attempts to yank a gem that has already been yanked
    Given I am signed up and confirmed as "the@owner.com/password"
    And I have a gem "RGem" with version "1.2.2"
    And I have a gem "RGem" with version "1.2.3"
    And I have an api key for "the@owner.com/password"
    And I've already pushed the gem "RGem-1.2.2.gem" with my api key
    And the gem "RGem" with version "1.2.2" has been indexed
    And I've already pushed the gem "RGem-1.2.3.gem" with my api key
    And the gem "RGem" with version "1.2.3" has been indexed
    And I have have already yanked the gem "RGem" with version "1.2.3" with my api key
    When I attempt to yank the gem "RGem" version "1.2.3" with my api key
    Then I should see "The version 1.2.3 has already been yanked"
