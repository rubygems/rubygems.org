Feature: Migrate Gems
  In order to share code with the world
  A rubygem developer
  Should be able to migrate gems from RubyForge

  Scenario: Migrating an existing unowned gem
    Given I am signed up and confirmed as "email@person.com/password"
    And a rubygem exists with name "MGem" and rubyforge project "mgem"
    And I have an api key for "email@person.com/password"
    When I migrate the gem "MGem" with my api key
    And I sign in as "email@person.com/password"
    And I go to my gems page
    Then I should see "MGem"

  Scenario: Migrating an unknown gem
  Scenario: Migrating an existing owned gem
