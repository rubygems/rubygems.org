Feature: Push Gems
  In order to share gems with the world
  A rubygem developer
  Should be able to push gems up to Gemcutter

    Scenario: User pushes new gem
      Given I am signed up and confirmed as "email@person.com/password"
      And I have a gem "RGem" with version "1.2.3"
      When I push the gem "RGem-1.2.3.gem" as "email@person.com/password"
      And I visit the gem page for "RGem"
      Then I should see "RGem"
      And I should see "1.2.3"

    Scenario: User pushes existing gem
      Given I am signed up and confirmed as "email@person.com/password"
      And I own a gem "RGem" with version "2.0.0"
      And I have a gem "RGem" with version "3.0.0"
      When I push the gem "RGem" with "email@person.com/password"
      And I visit the gem page for "RGem"
      Then I should see "RGem"
      And I should see "2.0.0"
      And I should see "3.0.0"

    Scenario: User pushes to someone else's gem
      Given I am signed up and confirmed as "email@person.com/password"
      And the gem "RGem" exists with version "2.0.0"
      And I have a gem "RGem" with version "1.0.0"
      When I push the gem "RGem" with "email@person.com/password"
      Then I should see "You do not have permission to push this gem."
