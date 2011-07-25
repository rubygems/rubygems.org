Feature: Web Hooks
  In order to keep the world abreast of new gem versions
  A rubygem developer
  Should be able to configure web hooks to be hit when a gem is pushed

  Background:
    Given I am signed up and confirmed as "email@person.com/password"

  Scenario: User pushes new gem with webhook
    Given I have a gem "fiddler" with version "1.0.0"
    And I have a gem "fiddler" with version "2.0.0"
    And I have an API key for "email@person.com/password"
    And I push the gem "fiddler-1.0.0.gem" with my API key
    When I have added a webhook for "http://example.org/webhook" to gem "fiddler" with my API key
    And I push the gem "fiddler-2.0.0.gem" with my API key
    And the system processes jobs
    Then the webhook "http://example.org/webhook" should receive a POST with gem "fiddler" at version "2.0.0"

  Scenario: User pushes older gem with webhook
    Given I have a gem "fiddler" with version "1.0.0"
    And I have a gem "fiddler" with version "0.5.0"
    And I have an API key for "email@person.com/password"
    And I push the gem "fiddler-1.0.0.gem" with my API key
    When I have added a webhook for "http://example.org/webhook" to gem "fiddler" with my API key
    And I push the gem "fiddler-0.5.0.gem" with my API key
    And the system processes jobs
    Then the webhook "http://example.org/webhook" should receive a POST with gem "fiddler" at version "0.5.0"

  Scenario: User pushes new gem after registering global webhook
    Given I have a gem "vodka" with version "1.2.3"
    And I have an API key for "email@person.com/password"
    When I have added a global webhook for "http://example.org/webhook" with my API key
    And I push the gem "vodka-1.2.3.gem" with my API key
    And the system processes jobs
    Then the webhook "http://example.org/webhook" should receive a POST with gem "vodka" at version "1.2.3"

  Scenario: User lists hooks for a gem in json
    Given the following rubygems exist:
      | name     |
      | mazeltov |
      | vodka    |
    And I have an API key for "email@person.com/password"
    And I have added a webhook for "http://example.org/webhook" to gem "mazeltov" with my API key
    And I have added a webhook for "http://example.org/webhook2" to gem "mazeltov" with my API key
    And I have added a webhook for "http://example.org/webhook3" to gem "vodka" with my API key
    And I have added a global webhook for "http://example.org/webhook4" with my API key
    And I have added a global webhook for "http://example.org/webhook5" with my API key
    When I list the webhooks as json with my API key
    Then I should see "http://example.org/webhook" under "mazeltov" in json
    And I should see "http://example.org/webhook2" under "mazeltov" in json
    And I should see "http://example.org/webhook3" under "vodka" in json
    And I should see "http://example.org/webhook4" under "all gems" in json
    And I should see "http://example.org/webhook5" under "all gems" in json

  Scenario: User lists hooks for a gem in yaml
    Given the following rubygems exist:
      | name     |
      | mazeltov |
      | vodka    |
    And I have an API key for "email@person.com/password"
    And I have added a webhook for "http://example.org/webhook" to gem "mazeltov" with my API key
    And I have added a webhook for "http://example.org/webhook2" to gem "mazeltov" with my API key
    And I have added a webhook for "http://example.org/webhook3" to gem "vodka" with my API key
    And I have added a global webhook for "http://example.org/webhook4" with my API key
    And I have added a global webhook for "http://example.org/webhook5" with my API key
    When I list the webhooks as yaml with my API key
    Then I should see "http://example.org/webhook" under "mazeltov" in yaml
    And I should see "http://example.org/webhook2" under "mazeltov" in yaml
    And I should see "http://example.org/webhook3" under "vodka" in yaml
    And I should see "http://example.org/webhook4" under "all gems" in yaml
    And I should see "http://example.org/webhook5" under "all gems" in yaml

  Scenario: User removes hook for a gem
    Given I have a gem "vodka" with version "1.0.0"
    And I have a gem "vodka" with version "2.0.0"
    And I have an API key for "email@person.com/password"
    And I push the gem "vodka-1.0.0.gem" with my API key
    And I have added a webhook for "http://example.org/webhook" to gem "vodka" with my API key
    When I have removed a webhook for "http://example.org/webhook" from gem "vodka" with my API key
    And I push the gem "vodka-2.0.0.gem" with my API key
    And the system processes jobs
    Then the webhook "http://example.org/webhook" should not receive a POST

  Scenario: User removes global hook
    Given I have a gem "vodka" with version "1.0.0"
    And I have a gem "vodka" with version "2.0.0"
    And I have an API key for "email@person.com/password"
    And I push the gem "vodka-1.0.0.gem" with my API key
    And I have added a global webhook for "http://example.org/webhook" with my API key
    When I have removed the global webhook for "http://example.org/webhook"
    And I push the gem "vodka-2.0.0.gem" with my API key
    And the system processes jobs
    Then the webhook "http://example.org/webhook" should not receive a POST

  Scenario: User test fires hook for a gem
    Given the following version exists:
      | rubygem     | number |
      | name: vodka | 1.2.3  |
    And I have an API key for "email@person.com/password"
    And I have added a webhook for "http://example.org/webhook" to gem "vodka" with my API key
    When I have fired a webhook to "http://example.org/webhook" for the "vodka" gem with my API key
    Then the webhook "http://example.org/webhook" should receive a POST with gem "vodka" at version "1.2.3"

  Scenario: User test fires global hook
    Given the following version exists:
      | rubygem         | number |
      | name: gemcutter | 1.0.0  |
    And I have an API key for "email@person.com/password"
    And I have added a global webhook for "http://example.org/webhook" with my API key
    When I have fired a webhook to "http://example.org/webhook" for all gems with my API key
    Then the webhook "http://example.org/webhook" should receive a POST with gem "gemcutter" at version "1.0.0"
