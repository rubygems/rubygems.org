@search

Feature: Search Advanced
  In order to discover more gems
  As a Ruby developer
  I should be able to use advanced search on gemcutter

  Scenario: Search in summaries and descriptions
    Given the following versions exist:
      | rubygem        | number | summary                                   | description             |
      | name: sinatra  | 0.0.1  | Sinatra is a DSL ...                      |                         |
      | name: vegas    | 0.0.1  | executable versions ... Sinatra/Rack apps |                         |
      | name: capybara | 0.0.1  |                                           | ... testing Sinatra ... |
    When I go to the homepage
    And I fill in "query" with "sinatra"
    And I press "Search"
    Then I should see these search results:
      | capybara (0.0.1) |
      | sinatra (0.0.1)  |
      | vegas (0.0.1)    |
