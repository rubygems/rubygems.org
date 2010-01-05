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
    When I have added a webhook for "http://example.org/webhook" to gem "fiddler" with my api key
    And I push the gem "fiddler-2.0.0.gem" with my api key
    And the system processes jobs
    Then the webhook "http://example.org/webhook" should receive a POST with gem "fiddler" at version "2.0.0"

  Scenario: User pushes older gem with webhook
    Given I am signed up and confirmed as "email@person.com/password"
    And I have a gem "fiddler" with version "1.0.0"
    And I have a gem "fiddler" with version "0.5.0"
    And I have an api key for "email@person.com/password"
    And I push the gem "fiddler-1.0.0.gem" with my api key
    When I have added a webhook for "http://example.org/webhook" to gem "fiddler" with my api key
    And I push the gem "fiddler-0.5.0.gem" with my api key
    And the system processes jobs
    Then the webhook "http://example.org/webhook" should receive a POST with gem "fiddler" at version "0.5.0"

  Scenario: User pushes new gem after registering global webhook
    Given I am signed up and confirmed as "email@person.com/password"
    And I have a gem "vodka" with version "1.2.3"
    And I have an api key for "email@person.com/password"
    When I have added a global webhook for "http://example.org/webhook" with my api key
    And I push the gem "vodka-1.2.3.gem" with my api key
    And the system processes jobs
    Then the webhook "http://example.org/webhook" should receive a POST with gem "vodka" at version "1.2.3"

  Scenario: User lists hooks for a gem
    Given I am signed up and confirmed as "email@person.com/password"
    And a rubygem exists with a name of "mazeltov"
    And a rubygem exists with a name of "vodka"
    And I have an api key for "email@person.com/password"
    And I have added a webhook for "http://example.org/webhook" to gem "mazeltov" with my api key
    And I have added a webhook for "http://example.org/webhook2" to gem "mazeltov" with my api key
    And I have added a webhook for "http://example.org/webhook3" to gem "vodka" with my api key
    And I have added a global webhook for "http://example.org/webhook4" with my api key
    And I have added a global webhook for "http://example.org/webhook5" with my api key
    When I list the webhooks with my api key
    Then I should see "http://example.org/webhook" under "mazeltov"
    And I should see "http://example.org/webhook2" under "mazeltov"
    And I should see "http://example.org/webhook3" under "vodka"
    And I should see "http://example.org/webhook4" under "all gems"
    And I should see "http://example.org/webhook5" under "all gems"

  Scenario: User removes hook for a gem
    Given I am signed up and confirmed as "email@person.com/password"
    And I have a gem "vodka" with version "1.0.0"
    And I have a gem "vodka" with version "2.0.0"
    And I have an api key for "email@person.com/password"
    And I push the gem "vodka-1.0.0.gem" with my api key
    And I have added a webhook for "http://example.org/webhook" to gem "vodka" with my api key
    When I have removed a webhook for "http://example.org/webhook" from gem "vodka" with my api key
    And I push the gem "vodka-2.0.0.gem" with my api key
    And the system processes jobs
    Then the webhook "http://example.org/webhook" should not receive a POST

  Scenario: User removes global hook
    Given I am signed up and confirmed as "email@person.com/password"
    And I have a gem "vodka" with version "1.0.0"
    And I have a gem "vodka" with version "2.0.0"
    And I have an api key for "email@person.com/password"
    And I push the gem "vodka-1.0.0.gem" with my api key
    And I have added a global webhook for "http://example.org/webhook" with my api key
    When I have removed the global webhook for "http://example.org/webhook"
    And I push the gem "vodka-2.0.0.gem" with my api key
    And the system processes jobs
    Then the webhook "http://example.org/webhook" should not receive a POST

  Scenario: User test fires hook for a gem
    Given I am signed up and confirmed as "email@person.com/password"
    And a rubygem exists with name "vodka" and version "1.2.3"
    And I have an api key for "email@person.com/password"
    And I have added a webhook for "http://example.org/webhook" to gem "vodka" with my api key
    When I have fired a webhook to "http://example.org/webhook" for the "vodka" gem with my api key
    Then the webhook "http://example.org/webhook" should receive a POST with gem "vodka" at version "1.2.3"

  Scenario: User test fires global hook
    Given I am signed up and confirmed as "email@person.com/password"
    And a rubygem exists with name "gemcutter" and version "1.0.0"
    And I have an api key for "email@person.com/password"
    And I have added a global webhook for "http://example.org/webhook" with my api key
    When I have fired a webhook to "http://example.org/webhook" for all gems with my api key
    Then the webhook "http://example.org/webhook" should receive a POST with gem "gemcutter" at version "1.0.0"
