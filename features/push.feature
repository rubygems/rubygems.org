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
      And I visit the gem page for "PGem"
      Then I should see "PGem"
      And I should see "1.0.0"
      And I should see "Second try"

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
