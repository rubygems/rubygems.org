Feature: Search
  In order to find a gem I want
  As a ruby developer 
  I should be able to search for gems on gemcutter

    Scenario: Search Titles
      Given a rubygem exists with a name of "sinatra"
      And a rubygem exists with a name of "mongrel"
      And a rubygem exists with a name of "thin"
      And a version exists for the "sinatra" rubygem with a description of "web framework"
      And a version exists for the "mongrel" rubygem with a description of "web server"
      And a version exists for the "thin" rubygem with a description of "web server"
      When I go to the homepage
      And I fill in "query" with "mon" 
      And I press "Search"
      Then I should see "mongrel"

    Scenario: Search Description
      Given a rubygem exists with a name of "LDAP"
      And a rubygem exists with a name of "twitter"
      And a rubygem exists with a name of "beer_laser"
      And a version exists for the "LDAP" rubygem with a description of "mail stuff"
      And a version exists for the "twitter" rubygem with a description of "social junk"
      And a version exists for the "beer_laser" rubygem with a description of "amazing beer"
      When I go to the homepage
      And I fill in "query" with "beer" 
      And I press "Search"
      Then I should see "beer_laser"

    Scenario: Search Case-Insensitively
      Given a rubygem exists with a name of "LDAP"
      And a rubygem exists with a name of "twitter"
      And a rubygem exists with a name of "beer_laser"
      And a version exists for the "LDAP" rubygem with a description of "mail stuff"
      And a version exists for the "twitter" rubygem with a description of "social junk"
      And a version exists for the "beer_laser" rubygem with a description of "amazing beer"
      When I go to the homepage
      And I fill in "query" with "ldap"
      And I press "Search"
      Then I should see "LDAP"

    Scenario: Exact match found
      Given a rubygem exists with a name of "paperclip"
      And a rubygem exists with a name of "foos-paperclip"
      And a rubygem exists with a name of "bars-paperclip"
      And a version exists for the "paperclip" rubygem with a description of "Official paperclip"
      And a version exists for the "foos-paperclip" rubygem with a description of "foo something else"
      And a version exists for the "bars-paperclip" rubygem with a description of "bar something else"
      When I go to the homepage
      And I fill in "query" with "paperclip"
      And I press "Search"
      Then I should see "Exact match"
 
    Scenario: Exact match not found
      Given a rubygem exists with a name of "foos-paperclip"
      And a rubygem exists with a name of "bars-paperclip"
      And a rubygem exists with a name of "bazs-paperclip"
      And a version exists for the "foos-paperclip" rubygem with a description of "foo something else"
      And a version exists for the "bars-paperclip" rubygem with a description of "bar something else"
      And a version exists for the "bazs-paperclip" rubygem with a description of "Official paperclip"
      When I go to the homepage
      And I fill in "query" with "paperclip"
      And I press "Search"
      Then I should not see "Exact match"
