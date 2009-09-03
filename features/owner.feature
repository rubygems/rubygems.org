Feature: Manage owners
  In order to unclench the iron fist of my gemtatorship
  A gem owner
  Should be able to add and remove gem owners

    Scenario: Gem owner user lists gem owners
      Given I am signed up and confirmed as "original@owner.org/password"
      And a user exists with an email of "new@owner.org"
      And I have an api key for "original@owner.org/password"
      And a rubygem exists with a name of "OGem"
      And the "OGem" rubygem is owned by "original@owner.org"
      When I list the owners of gem "OGem" with my api key
      Then I should see "original@owner.org"
      And I should not see "new@owner.org"

    Scenario: User who is not an owner of the gem lists gem owners
      Given I am signed up and confirmed as "non@owner.org/password"
      And a user exists with an email of "original@owner.org"
      And I have an api key for "non@owner.org/password"
      And a rubygem exists with a name of "OGem"
      When the "OGem" rubygem is owned by "original@owner.org"
      And I list the owners of gem "OGem" with my api key
      Then I should see "You do not have permission to manage this gem."

    Scenario: Gem owner adds another owner
      Given I am signed up and confirmed as "original@owner.org/password"
      And a user exists with an email of "new@owner.org"
      And I have an api key for "original@owner.org/password"
      And a rubygem exists with a name of "OGem"
      And the "OGem" rubygem is owned by "original@owner.org"
      When I add the owner "new@owner.org" to the rubygem "OGem" with my api key
      And I list the owners of gem "OGem" with my api key
      Then I should see "original@owner.org"
      And I should see "new@owner.org"

    Scenario: Gem owner attempts to add another owner that does not exist
      Given I am signed up and confirmed as "original@owner.org/password"
      And I have an api key for "original@owner.org/password"
      And a rubygem exists with a name of "OGem"
      And the "OGem" rubygem is owned by "original@owner.org"
      When I add the owner "new@owner.org" to the rubygem "OGem" with my api key
      Then I should see "Owner could not be found."

    Scenario: User who is not an owner of the gem attempts to add an owner
      Given I am signed up and confirmed as "non@owner.org/password"
      And a user exists with an email of "original@owner.org"
      And a user exists with an email of "new@owner.org"
      And I have an api key for "non@owner.org/password"
      And a rubygem exists with a name of "OGem"
      And the "OGem" rubygem is owned by "original@owner.org"
      When I add the owner "new@owner.org" to the rubygem "OGem" with my api key
      Then I should see "You do not have permission to manage this gem."

    Scenario: Gem owner removes an owner
      Given I am signed up and confirmed as "original@owner.org/password"
      And a user exists with an email of "new@owner.org"
      And I have an api key for "original@owner.org/password"
      And a rubygem exists with a name of "OGem"
      And the "OGem" rubygem is owned by "original@owner.org"
      And the "OGem" rubygem is owned by "new@owner.org"
      When I remove the owner "new@owner.org" from the rubygem "OGem" with my api key
      And I list the owners of gem "OGem" with my api key
      Then I should see "original@owner.org"
      And I should not see "new@owner.org"

    Scenario: Gem owner attempts to remove ownership from a user that is not an owner
      Given I am signed up and confirmed as "original@owner.org/password"
      And a user exists with an email of "new@owner.org"
      And I have an api key for "original@owner.org/password"
      And a rubygem exists with a name of "OGem"
      And the "OGem" rubygem is owned by "original@owner.org"
      When I remove the owner "new@owner.org" from the rubygem "OGem" with my api key
      Then I should see "Owner could not be found."

    Scenario: User who is not an owner of the gem attempts to remove an owner
      Given I am signed up and confirmed as "non@owner.org/password"
      And a user exists with an email of "original@owner.org"
      And I have an api key for "non@owner.org/password"
      And a rubygem exists with a name of "OGem"
      And the "OGem" rubygem is owned by "original@owner.org"
      When I remove the owner "original@owner.org" from the rubygem "OGem" with my api key
      Then I should see "You do not have permission to manage this gem."

    Scenario: Gem owner removes himself when he is not the last owner
      Given I am signed up and confirmed as "original@owner.org/password"
      And a user exists with an email of "new@owner.org"
      And I have an api key for "original@owner.org/password"
      And a rubygem exists with a name of "OGem"
      And the "OGem" rubygem is owned by "original@owner.org"
      And the "OGem" rubygem is owned by "new@owner.org"
      When I remove the owner "original@owner.org" from the rubygem "OGem" with my api key
      Then I should see "Owner removed successfully."

    Scenario: Gem owner removes himself when he is the last owner
      Given I am signed up and confirmed as "original@owner.org/password"
      And I have an api key for "original@owner.org/password"
      And a rubygem exists with a name of "OGem"
      And the "OGem" rubygem is owned by "original@owner.org"
      When I remove the owner "original@owner.org" from the rubygem "OGem" with my api key
      Then I should see "Unable to remove owner."
