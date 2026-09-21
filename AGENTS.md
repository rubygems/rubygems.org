- For bug fixes, demonstrate that the regression test fails for the original
  bug without the fix and passes with it.
- For security-sensitive changes, exercise the actual security gate with
  relevant allowed and denied cases. For denials, assert both the response
  and absence of unauthorized state changes and unauthorized side effects.
- `script/load-pg-dump` drops and recreates its target database without
  confirmation. Ensure Rails targets the same database, host,
  and port before running it.
- For backfills and other updates to existing data, prefer
  `MaintenanceTasks::Task` over migrations or ad hoc scripts; follow
  [Maintenance tasks](doc/maintenance-tasks.md) for design and rollout principles.
- For web-facing strings (views, components, flash messages, mailers), add
  keys to `config/locales/en.yml`, then run `bin/fill-locales`. API-only
  messages, Avo admin strings, and logs should stay plain English.
