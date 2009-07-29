Feature: Push Gems
  In order to share code with the world
  A rubygem developer
  Should be able to push gems up to Gemcutter

    Scenario: User pushes new gem
      Given I am signed up and confirmed as "email@person.com/password"
      And I have a gem "RGem" with version "1.2.3"
      And I have an api key for "email@person.com/password"
      When I push the gem "RGem-1.2.3.gem" with my api key
      And I go to the homepage
      And I follow "list"
      And I follow "R"
      And I follow "RGem (1.2.3)"
      Then I should see "RGem"
      And I should see "1.2.3"

    Scenario: User pushes existing gem
      Given I am signed up and confirmed as "email@person.com/password"
      And I have a gem "BGem" with version "2.0.0"
      And I have a gem "BGem" with version "3.0.0"
      And I have an api key for "email@person.com/password"
      And I push the gem "BGem-2.0.0.gem" with my api key
      When I push the gem "BGem-3.0.0.gem" with my api key
      And I go to the homepage
      And I follow "list"
      And I follow "B"
      And I follow "BGem (3.0.0)"
      Then I should see "BGem"
      And I should see "2.0.0"
      And I should see "3.0.0"
