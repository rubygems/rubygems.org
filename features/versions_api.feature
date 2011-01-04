Feature: List gem versions API
  In order to see all the versions of a specific gem
  An API consumer
  Should be able to fetch them

    Scenario: API consumer fetches list of versions for a gem
      Given a rubygem exists with name "MyGem" and version "1.0.0"
      When I list the versions of the rubygem "MyGem"
      Then I should see "MyGem-1.0.0"
      And I should see "Some awesome gem"