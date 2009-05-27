Feature: Rails helper generator
  In order to better do Test-Driven Development with Rails
  As a user
  I want to generate just the module and test I need.

  Scenario: Helper
    Given a Rails app
    And the coulda plugin is installed
    When I generate a helper named "Navigation"
    Then a helper should be generated for "Navigation"
    And a helper test should be generated for "Navigation"

