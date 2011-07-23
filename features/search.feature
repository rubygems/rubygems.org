Feature: Search
  In order to find a gem I want
  As a ruby developer 
  I should be able to search for gems on gemcutter

  Scenario Outline: Search
    Given the following versions exist:
      | rubygem          | description  |
      | name: LDAP       | mail stuff   |
      | name: twitter    | social junk  |
      | name: beer_laser | amazing beer |
    When I go to the homepage
    And I fill in "query" with "<query>"
    And I press "Search"
    Then I should see "<result>"

    Examples:
      | query      | result       |
      | twitter    | social junk  |
      | beer       | beer_laser   |
      | ldap       | mail stuff   |
      | beer laser | amazing beer |
      | LDAP       | Exact match  |

  Scenario: Exact match not found
    Given the following version exists:
      | rubygem              | description |
      | name: foos-paperclip | paperclip   |
    When I go to the homepage
    And I fill in "query" with "paperclip"
    And I press "Search"
    Then I should not see "Exact match"
    But I should see "foos-paperclip"

  Scenario: The only pushed version of a gem is yanked
    Given the following version exists:
      | rubygem    | number | indexed |
      | name: RGem | 1.0.0  | false   |
    When I go to the homepage
    And I fill in "query" with "RGem"
    And I press "Search"
    Then I should not see "RGem (1.0.0)"

  Scenario: The most recent version of a gem is yanked
    Given the following versions exist:
      | rubygem    | number | indexed |
      | name: RGem | 1.2.1  | true    |
      | name: RGem | 1.2.2  | false   |
    When I go to the homepage
    And I fill in "query" with "RGem"
    And I press "Search"
    And I should see "RGem (1.2.1)"
    And I should not see "RGem (1.2.2)"
