Feature: Web Hooks
  In order to keep the world abreast of new gem versions
  A rubygem developer
  Should be able to configure web hooks to be hit when a gem is pushed

    Scenario: User pushes new gem with webhook
      Given I am signed up and confirmed as "email@person.com/password"
      And I have a gem "RGem" with version "1.2.3"
      And I have an api key for "email@person.com/password"
      And I have added a webhook "http://example.org/webhook" to gem "RGem"
      When I push the gem "RGem-1.2.3.gem" with my api key
      And the system processes jobs
      Then the webhook "http://example.org/webhook" should receive a POST

    Scenario: User pushes new gem after registering global webhook
      Given I am signed up and confirmed as "email@person.com/password"
      And I have a gem "RGem" with version "1.2.3"
      And I have an api key for "email@person.com/password"
      And I have added a webhook "http://example.org/webhook" to gem "*"
      When I push the gem "RGem-1.2.3.gem" with my api key
      And the system processes jobs
      Then the webhook "http://example.org/webhook" should receive a POST
