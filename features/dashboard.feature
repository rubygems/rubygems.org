Feature: Dashboard
  In order to see the status of gems to which I've subscribed
  A user
  Should be able to see a list of updates in their feed

  Background:
    Given I am signed up as "email@person.com"

  Scenario: User goes to their dashboard
    Given the following rubygems exist:
      | name     |
      | ffi      |
      | sandworm |
      | fireworm |
    And the following versions exist:
      | rubygem        | number | platform    |
      | name: sandworm | 2.0.0  | ruby        |
      | name: ffi      | 1.0.0  | java        |
      | name: ffi      | 1.0.0  | x86-mswin32 |
      | name: fireworm | 1.0.0  | ruby        |
    And the following subscriptions exist:
      | user                    | rubygem        |
      | email: email@person.com | name: ffi      |
      | email: email@person.com | name: sandworm |
    And the following ownerships exist:
      | user                    | rubygem        |
      | email: email@person.com | name: fireworm |
    And I download the rubygem "fireworm" version "1.0.0" 1001 times
    And I download the rubygem "sandworm" version "2.0.0" 1008 times
    When I sign in as "email@person.com"
    And I go to the dashboard
    And I should see "ffi"
    And I should see "java"
    And I should see "x86-mswin32"
    And I should see "1,001 downloads"
    And I should see "1,008 downloads"

  Scenario: Yanked gem is hidden from listing
    Given the following versions exist:
      | rubygem    | number | indexed |
      | name: RGem | 1.2.2  | true    |
      | name: RGem | 1.2.3  | false   |
    When I go to the dashboard
    And I follow "RGem"
    Then I should not see "yanked"
    And I should see "1.2.2"
    And I should see "Show all versions (2 total)"
