Feature: Web Hooks
  In order to keep the world abreast of new gem versions
  A rubygem developer
  Should be able to configure web hooks to be hit when a gem is pushed

  Scenario: User pushes new gem with webhook
    Given I am signed up and confirmed as "email@person.com/password"
    And I have a gem "fiddler" with version "1.0.0"
    And I have a gem "fiddler" with version "2.0.0"
    And I have an api key for "email@person.com/password"
    And I push the gem "fiddler-1.0.0.gem" with my api key
    And I have added a webhook for "http://example.org/webhook" to gem "fiddler"
    When I push the gem "fiddler-2.0.0.gem" with my api key
    And the system processes jobs
    Then the webhook "http://example.org/webhook" should receive a POST with gem "fiddler" at version "2.0.0"

  Scenario: User pushes older gem with webhook
    Given I am signed up and confirmed as "email@person.com/password"
    And I have a gem "fiddler" with version "1.0.0"
    And I have a gem "fiddler" with version "0.5.0"
    And I have an api key for "email@person.com/password"
    And I push the gem "fiddler-1.0.0.gem" with my api key
    And I have added a webhook for "http://example.org/webhook" to gem "fiddler"
    When I push the gem "fiddler-0.5.0.gem" with my api key
    And the system processes jobs
    Then the webhook "http://example.org/webhook" should receive a POST with gem "fiddler" at version "0.5.0"

  Scenario: User pushes new gem after registering global webhook
    Given I am signed up and confirmed as "email@person.com/password"
    And I have a gem "vodka" with version "1.2.3"
    And I have an api key for "email@person.com/password"
    And I have added a global webhook for "http://example.org/webhook"
    When I push the gem "vodka-1.2.3.gem" with my api key
    And the system processes jobs
    Then the webhook "http://example.org/webhook" should receive a POST with gem "vodka" at version "1.2.3"
