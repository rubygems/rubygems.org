Feature: List gems API
  In order to see all the gems I work on
  A gem owner
  Should be able to list their gems

    Scenario: Gem owner user lists their gems
      Given I am signed up and confirmed as "original@owner.org/password"
      And I have an api key for "original@owner.org/password"
      And a rubygem exists with name "MyGem" and version "1.0.0"
      And the "MyGem" rubygem is owned by "original@owner.org"
      When I list the gems with my api key
      Then I should see "MyGem"