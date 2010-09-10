Feature: Dashboard
  In order to see the status of gems to which I've subscribed
  A user
  Should be able to see a list of updates in their feed

  Scenario: User goes to their dashboard
    Given I am using HTTPS
    And I am signed up and confirmed as "email@person.com/password"
    And a rubygem exists with a name of "ffi"
    And a version exists for the "ffi" rubygem with a platform of "java"
    And a version exists for the "ffi" rubygem with a platform of "x86-mswin32"
    And a subscription by "email@person.com" to the gem "ffi"
    When I sign in as "email@person.com/password"
    And I go to the dashboard
    And I should see "ffi"
    And I should see "java"
    And I should see "x86-mswin32"