Feature: Top Downloads API
  In order to see the most-downloaded gems for today
  A user
  Can access the top downloads api

  Scenario: GET
    Given a rubygem exists with name "foo" and version "1.0"
    And I download the rubygem "foo" version "1.0" 7 times
    And the version has a description of "foo 1.0"
    And a rubygem exists with name "bar" and version "1.0"
    And I download the rubygem "bar" version "1.0" 8 times
    And the version has a description of "bar 1.0"
    When I go to the top downloads api
    Then I should see "foo"
    And I should see "bar"
