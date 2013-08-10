Feature: List gems API
  In order to see all the gems I work on
  A gem owner
  Should be able to list their gems

  Scenario: Anonymous user lists gems for owner
    Given the following user exists:
      | email            | handle   |
      | user@example.com | myhandle |
    And the following version exists:
      | rubygem    | number |
      | name: AGem | 1.0.0  |
    And the following ownership exists:
      | rubygem    | user                    |
      | name: AGem | email: user@example.com |
      | name: BGem |                         |
    When I list the gems for owner "myhandle"
    Then I should see "AGem"
    And I should not see "BGem"

  Scenario: Anonymous user lists gems for unknown user
    When I list the gems for owner "nobody"
    Then I should see "Owner could not be found."

  Scenario: Gem owner user lists their gems
    Given I am signed up as "original@owner.org"
    And I have an API key for "original@owner.org/password"
    And the following version exists:
      | rubygem     | number |
      | name: MyGem | 1.0.0  |
    And the following ownership exists:
      | rubygem     | user                      |
      | name: MyGem | email: original@owner.org |
    When I list the gems with my API key
    Then I should see "MyGem"

  Scenario: Gem versions include all gem version data
    Given the following version exists:
      | rubygem                  | number | licenses |
      | name: testgemwithlicense | 1.0.0  | MIT      |
    When I GET "/api/v1/versions/testgemwithlicense.json"
    Then the JSON response should include all of the gem version metadata

  Scenario: Gem has MIT license
    Given the following version exists:
      | rubygem                     | number | licenses |
      | name: testgemwithmitlicense | 1.0.0  | MIT      |
    When I GET "/api/v1/versions/testgemwithmitlicense.json"
    Then the returned JSON should include licenses:MIT

  Scenario: Gem has dual (MIT/Proprietary) licenses
    Given the following version exists:
      | rubygem                       | number | licenses        |
      | name: testgemwithduallicenses | 1.0.0  | MIT,Proprietary |
    When I GET "/api/v1/versions/testgemwithduallicenses.json"
    Then the returned JSON should include licenses:GPLv2,Proprietary

  Scenario: Gem has no license
    Given the following version exists:
      | rubygem                    | number | licenses |
      | name: testgemwithnolicense | 1.0.0  |          |
    When I GET "/api/v1/versions/testgemwithnolicense.json"
    Then the returned JSON should include licenses:
