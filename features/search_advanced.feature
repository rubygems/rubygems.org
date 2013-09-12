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
    When I search for "sinatra"
    Then I should see these search results:
      | capybara (0.0.1) |
      | sinatra (0.0.1)  |
      | vegas (0.0.1)    |

Scenario: Searching in authors
    Given gems with these properties exist:
      | name     | version | authors                        | downloads |
      | sinatra  | 0.0.1   | Blake Mizerany, Ryan Tomayko   | 500       |
      | beefcake | 0.0.1   | Blake Mizerany                 | 50        |
      | vegas    | 0.0.1   | Aaron Quint                    | 5         |
    When I search for "author:blake"
    Then I should see these search results:
      | sinatra (0.0.1)   |
      | beefcake (0.0.1)  |
