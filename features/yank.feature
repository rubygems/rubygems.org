Feature: Delete Gems
  In order to remove my botched release
  As a rubygem developer
  I want to delete gems from Gemcutter

  Scenario: User yanks a gem
    Given I am signed up as "email@person.com"
    And I have an API key for "email@person.com/password"
    And the following ownership exists:
      | rubygem    | user                    |
      | name: rgem | email: email@person.com |
    And the following versions exist:
      | rubygem    | number |
      | name: rgem | 1.2.2  |
      | name: rgem | 1.2.3  |
    When I yank the gem "rgem" version "1.2.3" with my API key
    And I go to the dashboard
    Then I should see "rgem"
    And I visit the gem page for "rgem" version "1.2.3"
    Then I should see "This gem has been yanked"
    And I visit the gem page for "rgem"
    Then I should see the version "1.2.2" featured

  Scenario: User yanks the last version of a gem and a new gem is pushed on that namespace
    Given I am signed up as "email@person.com"
    And I have an API key for "email@person.com/password"
    And the following ownership exists:
      | rubygem    | user                    |
      | name: rgem | email: email@person.com |
    And the following versions exist:
      | rubygem    | number |
      | name: rgem | 1.2.3  |
    When I yank the gem "rgem" version "1.2.3" with my API key
    And I go to the dashboard
    And I go to the "rgem" rubygem page
    Then I should see "This gem has been yanked"

    Given I am signed up as "new@owner.com"
    And I have a gem "rgem" with version "0.1.0"
    And I have an API key for "new@owner.com/password"
    When I push the gem "rgem-0.1.0.gem" with my API key
    And I visit the gem page for "rgem"
    Then I should see "rgem"
    And I should see "0.1.0"
    When I list the owners of gem "rgem" with my API key
    Then I should see "new@owner.com"
    And I should not see "old@owner.com"

  Scenario: User who is not owner attempts to yank a gem
    Given I am signed up as "non@owner.org"
    And I have an API key for "non@owner.org/password"
    And the following version exists:
      | rubygem    | number | indexed |
      | name: rgem | 1.2.3  | true    |
    And the following ownership exists:
      | rubygem    | user                 |
      | name: rgem | email: the@owner.org |
    When I attempt to yank the gem "rgem" version "1.2.3" with my API key
    Then I should see "You do not have permission to yank this gem."

  Scenario: User attempts to yank a nonexistent version of a gem
    Given I am signed up as "the@owner.com"
    And I have an API key for "the@owner.com/password"
    And the following ownership exists:
      | rubygem    | user                 |
      | name: rgem | email: the@owner.com |
    And the following versions exist:
      | rubygem    | number |
      | name: rgem | 1.2.3  |
    When I attempt to yank the gem "rgem" version "1.2.4" with my API key
    Then I should see "The version 1.2.4 does not exist."

  Scenario: User attempts to yank a gem that has already been yanked
    Given I am signed up as "the@owner.com"
    And I have an API key for "the@owner.com/password"
    And the following ownership exists:
      | rubygem    | user                 |
      | name: rgem | email: the@owner.com |
    And the following versions exist:
      | rubygem    | number | indexed |
      | name: rgem | 1.2.3  | false   |
    When I attempt to yank the gem "rgem" version "1.2.3" with my API key
    Then I should see "The version 1.2.3 has already been yanked"

  Scenario: User unyanks a gem
    Given I am signed up as "the@owner.com"
    And I have an API key for "the@owner.com/password"
    And the following ownership exists:
      | rubygem    | user                 |
      | name: rgem | email: the@owner.com |
    And the following versions exist:
      | rubygem    | number | indexed |
      | name: rgem | 1.2.3  | false   |
    When I unyank the gem "rgem" version "1.2.3" with my API key
    And I go to the dashboard
    And I follow "rgem"
    Then I should not see "This gem has been yanked."
