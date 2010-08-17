Feature: Resolver endpoint
  Background:
    Given a rubygem exists with a name of "terran"
    And a rubygem exists with a name of "zerg"
    And a rubygem exists with a name of "protoss"
    And the following versions exist:
      | Rubygem | Number | Platform |
      | terran  | 1.0.0  | mswin32  |
      | terran  | 2.0.0  | mswin32  |
      | protoss | 1.0.0  | ruby     |
      | zerg    | 1.0.0  | java     |
    And the following dependencies exist:
      | Version              | Rubygem   | Requirements |
      | terran-1.0.0-mswin32 | scv       | >= 0         |
      | terran-1.0.0-mswin32 | marine    | = 0.0.1      |
      | terran-2.0.0-mswin32 | reaper    | >= 0         |
      | terran-2.0.0-mswin32 | siegetank | ~> 1.0.0     |
      | protoss-1.0.0        | stalker   | <= 2.0.0     |
      | protoss-1.0.0        | zealot    | = 1.0.0      |
      | zerg-1.0.0-java      | drone     | >= 0         |

  Scenario: Resolve terran and protoss
    When I request "/api/v1/dependencies?gems=terran,protoss"
    Then I should see the following dependencies for "terran-1.0.0-mswin32":
      | Name   | Requirements |
      | scv    | >= 0         |
      | marine | = 0.0.1      |
    And I should see the following dependencies for "terran-2.0.0-mswin32":
      | Name      | Requirements |
      | reaper    | >= 0         |
      | siegetank | ~> 1.0.0     |
    And I should see the following dependencies for "protoss-1.0.0":
      | Name    | Requirements |
      | stalker | <= 2.0.0     |
      | zealot  | = 1.0.0      |
    And I should not see any dependencies for "zerg" version "1.0.0"
