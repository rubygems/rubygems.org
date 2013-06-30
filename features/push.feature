Feature: Push Gems
  In order to share code with the world
  A rubygem developer
  Should be able to push gems up to Gemcutter

  Scenario: User pushes new gem and sees metadata
    Given I am signed up as "email@person.com"
    And I have a gem "RGem" with version "1.2.3" and the following attributes:
      | authors  | description  | license |
      | John Doe | The best gem | MIT     |
    And I have an API key for "email@person.com/password"
    When I push the gem "RGem-1.2.3.gem" with my API key
    And I visit the gem page for "RGem"
    Then I should see "RGem"
    And I should see "1.2.3"
    And I should see "John Doe"
    And I should see "The best gem"
    And I should see "MIT"

  Scenario: User pushes new gem and sees metadata
    Given I am signed up as "email@person.com"
    And I have a gem "RGem" with version "1.2.3" and the following attributes:
      | authors  | description  |
      | John Doe | The best gem |
    And I have an API key for "email@person.com/password"
    When I push the gem "RGem-1.2.3.gem" with my API key
    And I visit the gem page for "RGem"
    Then I should see "RGem"
    And I should see "1.2.3"
    And I should see "John Doe"
    And I should see "The best gem"

  Scenario: User pushes existing version of existing gem
    Given I am signed up as "email@person.com"
    And I have a gem "PGem" with version "1.0.0" and summary "First try"
    And I have an API key for "email@person.com/password"
    When I push the gem "PGem-1.0.0.gem" with my API key
    And I visit the gem page for "PGem"
    Then I should see "PGem"
    And I should see "1.0.0"
    And I should see "First try"

    When I have a gem "PGem" with version "1.0.0" and summary "Second try"
    And I push the gem "PGem-1.0.0.gem" with my API key
    Then the response should contain "Repushing of gem versions is not allowed."
    And the response should contain "Please use `gem yank` to remove bad gem releases."
    And I visit the gem page for "PGem"
    And I should see "PGem"
    And I should see "1.0.0"
    And I should see "First try"

  Scenario: User pushes new version of existing gem
    Given I am signed up as "email@person.com"
    And I have an API key for "email@person.com/password"
    And I have a gem "BGem" with version "2.0.0"
    And I push the gem "BGem-2.0.0.gem" with my API key
    And I have a gem "BGem" with version "3.0.0"
    When I push the gem "BGem-3.0.0.gem" with my API key
    And I visit the gem page for "BGem"
    Then I should see "BGem"
    And I should see "2.0.0"
    And I should see "3.0.0"

  Scenario: User pushes gem with bad url
    Given I am signed up as "email@person.com"
    And I have an API key for "email@person.com/password"
    And I have a gem "badurl" with version "1.0.0" and homepage "badurl.com"
    When I push the gem "badurl-1.0.0.gem" with my API key
    Then I should see "Home does not appear to be a valid URL"

  Scenario: User pushes gem with bad authors
    Given I am signed up as "email@person.com"
    And I have an API key for "email@person.com/password"
    And I have a gem "badauthors" with version "1.0.0" and authors "[3]"
    When I push the gem "badauthors-1.0.0.gem" with my API key
    Then I should see "Authors must be an Array of Strings"

  Scenario: User pushes gem with a runtime dependency
    Given I am signed up as "email@person.com"
    And I have an API key for "email@person.com/password"
    And I have a gem "knowndeps" with version "1.0.0" and runtime dependency "knowngem"
    And a rubygem exists with name "knowngem" and version "0.0.0"
    When I push the gem "knowndeps-1.0.0.gem" with my API key
    And I visit the gem page for "knowndeps"
    Then I should see "knowndeps"
    And I should see "1.0.0"
    And I should see "knowngem" as a runtime dependency

  Scenario: User pushes gem with unknown runtime dependency
    Given I am signed up as "email@person.com"
    And I have an API key for "email@person.com/password"
    And I have a gem "unkdeps" with version "1.0.0" and runtime dependency "unknown"
    When I push the gem "unkdeps-1.0.0.gem" with my API key
    And I visit the gem page for "unkdeps"
    Then I should see "unkdeps"
    And I should see "1.0.0"
    And I should see "unknown" as a runtime dependency

  @wip
  Scenario: User pushes gem with missing :rubygems_version, :specification_version, :name, :version, :date, :summary, :require_paths

  Scenario: User pushes file that is not a gem
    Given I am signed up as "email@person.com"
    And I have an API key for "email@person.com/password"
    When I push an invalid .gem file
    Then I should see "RubyGems.org cannot process this gem."
    And I should not see "Error:"
    And I should not see "No metadata found!"

  Scenario: User pushes gem with bad description
    Given I am signed up as "email@person.com"
    And I have an API key for "email@person.com/password"
    And I have a gem "bad-characters" with version "0.0.0" and summary "Breaking this field later"
    When I push the fixture gem "bad-characters-1.0.0.gem" with my API key
    Then I should see "RubyGems.org cannot process this gem. Please try rebuilding it and installing it locally to make sure it's valid."
