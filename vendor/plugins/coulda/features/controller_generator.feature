Feature: Rails controller generator
  In order to better do Test-Driven Development with Rails
  As a user
  I want to generate Shoulda & Factory Girl tests for only RESTful action I need.

  Scenario: Controller generator for index action
    Given a Rails app
    And the coulda plugin is installed
    When I generate a "Posts" controller with "index" action
    Then a standard "index" functional test for "posts" should be generated
    And an empty "index" controller action for "posts" should be generated

  Scenario: Controller generator for new action
    Given a Rails app
    And the coulda plugin is installed
    When I generate a "Posts" controller with "new" action
    Then a standard "new" functional test for "posts" should be generated
    And a "new" controller action for "posts" should be generated

  Scenario: Controller generator for create action
    Given a Rails app
    And the coulda plugin is installed
    When I generate a "Posts" controller with "create" action
    Then a standard "create" functional test for "posts" should be generated
    And a "create" controller action for "posts" should be generated

  Scenario: Controller generator for show action
    Given a Rails app
    And the coulda plugin is installed
    When I generate a "Posts" controller with "show" action
    Then a standard "show" functional test for "posts" should be generated
    And a "show" controller action for "posts" should be generated

  Scenario: Controller generator for edit action
    Given a Rails app
    And the coulda plugin is installed
    When I generate a "Posts" controller with "edit" action
    Then a standard "edit" functional test for "posts" should be generated
    And a "edit" controller action for "posts" should be generated

  Scenario: Controller generator for update action
    Given a Rails app
    And the coulda plugin is installed
    When I generate a "Posts" controller with "update" action
    Then a standard "update" functional test for "posts" should be generated
    And a "update" controller action for "posts" should be generated

  Scenario: Controller generator for destroy action
    Given a Rails app
    And the coulda plugin is installed
    When I generate a "Posts" controller with "destroy" action
    Then a standard "destroy" functional test for "posts" should be generated
    And a "destroy" controller action for "posts" should be generated

