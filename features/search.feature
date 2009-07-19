Feature: Search
  In order to find a gem I want
  As a ruby developer 
  I should be able to search for gems on gemcutter
  
    Scenario: Search Titles
      Given a rubygem exists with a name of "sinatra"
      And a rubygem exists with a name of "mongrel"
      And a rubygem exists with a name of "thin"
      When I go to the homepage
      And I follow "search"
      And I fill in "query" with "mon" 
      And I press "Search"
      Then I should see "mongrel"