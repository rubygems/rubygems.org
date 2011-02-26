Feature: Dashboard
  In order to see the status of gems to which I''ve subscribed
  A user
  Should be able to see a list of updates in their feed

  Scenario: User goes to their dashboard
    Given I am using HTTPS
    And I am signed up and confirmed as "email@person.com/password"
    And a rubygem exists with a name of "ffi"
    And a rubygem exists with a name of "sandworm"
    And a version exists for the "sandworm" rubygem with a number of "2.0.0"
    And a version exists for the "ffi" rubygem with a platform of "java"
    And a version exists for the "ffi" rubygem with a platform of "x86-mswin32"
    And a subscription by "email@person.com" to the gem "ffi"
    And a subscription by "email@person.com" to the gem "sandworm"
    And a rubygem exists with a name of "fireworm"
    And a version exists for the "fireworm" rubygem with a number of "1.0.0"
    And the "fireworm" rubygem is owned by "email@person.com"
    And I download the rubygem "fireworm" version "1.0.0" 1001 times
    And I download the rubygem "sandworm" version "2.0.0" 1008 times
    When I sign in as "email@person.com/password"
    And I go to the dashboard
    And I should see "ffi"
    And I should see "java"
    And I should see "x86-mswin32"
    And I should see "1,001 downloads"
    And I should see "1,008 downloads"
    