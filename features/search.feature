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

    Scenario: Search Description
      Given a rubygem exists with a name of "LDAP"
      And a rubygem exists with a name of "twitter"
      And a rubygem exists with a name of "beer laser"
      And a version exists for the "LDAP" rubygem with a description of "mail stuff"
      And a version exists for the "twitter" rubygem with a description of "social junk"
      And a version exists for the "beer laser" rubygem with a description of "amazing beer"
      When I go to the homepage
      And I follow "search"
      And I fill in "query" with "beer" 
      And I press "Search"
      Then I should see "beer laser"
