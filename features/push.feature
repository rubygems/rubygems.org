Feature: Push Gems
  In order to share code with the world
  A rubygem developer
  Should be able to push gems up to Gemcutter

  Scenario: User pushes new gem
    Given I am signed up and confirmed as "email@person.com/password"
    And I have a gem "RGem" with version "1.2.3"
    And I have an api key for "email@person.com/password"
    When I push the gem "RGem-1.2.3.gem" with my api key
    And I visit the gem page for "RGem"
    Then I should see "RGem"
    And I should see "1.2.3"

  Scenario: User pushes existing version of existing gem
    Given I am signed up and confirmed as "email@person.com/password"
    And I have a gem "PGem" with version "1.0.0" and summary "First try"
    And I have an api key for "email@person.com/password"
    When I push the gem "PGem-1.0.0.gem" with my api key
    And I visit the gem page for "PGem"
    Then I should see "PGem"
    And I should see "1.0.0"
    And I should see "First try"

    When I have a gem "PGem" with version "1.0.0" and summary "Second try"
    And I push the gem "PGem-1.0.0.gem" with my api key
    Then the response should contain "Repushing of gem versions is not allowed."
    And the response should contain "Please use `gem yank` to remove bad gem releases."
    And I visit the gem page for "PGem"
    And I should see "PGem"
    And I should see "1.0.0"
    And I should see "First try"

  Scenario: User pushes new version of existing gem
    Given I am signed up and confirmed as "email@person.com/password"
    And I have an api key for "email@person.com/password"
    And I have a gem "BGem" with version "2.0.0"
    And I push the gem "BGem-2.0.0.gem" with my api key
    And I have a gem "BGem" with version "3.0.0"
    When I push the gem "BGem-3.0.0.gem" with my api key
    And I visit the gem page for "BGem"
    Then I should see "BGem"
    And I should see "2.0.0"
    And I should see "3.0.0"

  Scenario: User pushes gem with bad url
    Given I am signed up and confirmed as "email@person.com/password"
    And I have an api key for "email@person.com/password"
    And I have a gem "badurl" with version "1.0.0" and homepage "badurl.com"
    When I push the gem "badurl-1.0.0.gem" with my api key
    Then I should see "Home does not appear to be a valid URL"

  Scenario: User pushes gem with bad name
    Given I am signed up and confirmed as "email@person.com/password"
    And I have an api key for "email@person.com/password"
    And I have a bad gem "['badname']" with version "1.0.0"
    When I push the gem "badname-1.0.0.gem" with my api key
    Then I should see "Name must be a String"

  Scenario: User pushes gem with bad authors
    Given I am signed up and confirmed as "email@person.com/password"
    And I have an api key for "email@person.com/password"
    And I have a gem "badauthors" with version "1.0.0" and authors "[3]"
    When I push the gem "badauthors-1.0.0.gem" with my api key
    Then I should see "Authors must be an Array of Strings"

  Scenario: User pushes gem with bad runtime dependency
    Given I am signed up and confirmed as "email@person.com/password"
    And I have an api key for "email@person.com/password"
    And I have a gem "baddeps" with version "1.0.0" and runtime dependency "unknown"
    When I push the gem "baddeps-1.0.0.gem" with my api key
    Then I should see "Please specify dependencies that exist on RubyGems.org"
    And the rubygem "unknown" does not exist

  @wip
  Scenario: User pushes gem with missing :rubygems_version, :specification_version, :name, :version, :date, :summary, :require_paths

  Scenario: User pushes file that is not a gem
    Given I am signed up and confirmed as "email@person.com/password"
    And I have an api key for "email@person.com/password"
    When I push an invalid .gem file
    Then I should see "RubyGems.org cannot process this gem."
    And I should not see "Error:"
    And I should not see "No metadata found!"
