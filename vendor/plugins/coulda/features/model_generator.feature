Feature: Rails model generator
  In order to better do Test-Driven Development with Rails
  As a user
  I want to generate a Factory definition and Shoulda tests.

  Scenario: Model generator without attributes
    Given a Rails app
    And the coulda plugin is installed
    When I generate a model named "User"
    Then a factory should be generated for "User"
    And a unit test should be generated for "User"

  Scenario: Model generator with attributes
    Given a Rails app
    And the coulda plugin is installed
    When I generate a model "User" with a string "email"
    Then a factory for "User" should have an "email" string
    And a unit test should be generated for "User"

  Scenario: Model generator with association
    Given a Rails app
    And the coulda plugin is installed
    When I generate a model "Post" that belongs to a "User"
    Then a factory for "Post" should have an association to "User"
    And the "Post" unit test should have "should_belong_to :user" macro
    And the "Post" unit test should have "should_have_index :user_id" macro
    And the "posts" table should have db index on "user_id"
    And the "Post" model should have "belongs_to :user" macro

  Scenario: Model generator with Paperclip
    Given a Rails app
    And the coulda plugin is installed
    When I generate a model "Design" with file "Image"
    Then the "Design" model should have "has_attached_file :image" macro
    And the "Design" unit test should have "should_have_attached_file :image" macro
    And the "designs" table should have paperclip columns for "image"

