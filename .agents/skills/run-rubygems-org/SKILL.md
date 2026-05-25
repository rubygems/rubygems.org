---
name: run-rubygems-org
description: Run rubygems.org locally — boot the Rails server, hit it with curl, screenshot pages with headless Chrome. Use when asked to run, start, boot, smoke-test, or screenshot the rubygems.org / gemcutter app.
---

# Run rubygems.org

A Rails 8 app (internal name: `gemcutter`) that needs Postgres, OpenSearch, and Memcached. Backing services run in Docker; everything else (Ruby 4, Puma, headless Chrome) runs on the host.

**The agent path is `./.agents/skills/run-rubygems-org/smoke.sh`** — it brings services up, boots Rails on :3000 if it isn't already, curls four key endpoints, and writes three PNG screenshots to `tmp/run-skill/`.

All paths in this doc are relative to the repo root (`/Users/colby/Developer/rubygems.org`).

> Canonical location: `.agents/skills/run-rubygems-org/` — the cross-tool skill convention picked up by Codex CLI, OpenCode, and Gemini CLI. Claude Code reads it through the symlink at `.claude/skills/run-rubygems-org/`.
>
> **If `smoke.sh` fails, see "When this skill fails" below before improvising — [`LEARNINGS.md`](LEARNINGS.md) likely has your fix.**

## Prerequisites (one-time)

You need Ruby 4 (via `mise`/`asdf` from `.ruby-version`), and Postgres + OpenSearch + Memcached reachable on `127.0.0.1:5432/9200/11211`. `smoke.sh` doesn't care *how* they're running — Docker, brew services, apt, or already-on-the-host — it just probes the ports.

If you're on a fresh machine, pick whichever path you prefer:

```bash
# Path A: Docker (one command for all three backing services)
mise install                  # ruby 4.0.5 per .ruby-version
docker compose up -d db cache search
bin/setup                     # bundle, db:prepare, db:seed, playwright install

# Path B: Native (macOS via Homebrew)
mise install
brew install postgresql@14 memcached
brew services start postgresql@14
brew services start memcached
# OpenSearch isn't in Homebrew; run it via docker even in a "native" setup:
docker run -d -p 9200:9200 \
  -e discovery.type=single-node -e DISABLE_SECURITY_PLUGIN=true \
  -e 'OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m' \
  opensearchproject/opensearch:2.13.0
bin/setup
```

See `CONTRIBUTING.md` > Development Setup for the Linux/apt variant. `bin/setup` installs Playwright's bundled Chromium into `~/Library/Caches/ms-playwright/chromium-*/` — `smoke.sh` uses that same binary for screenshots, so you don't need a separate browser.

## Run (agent path — preferred)

```bash
./.agents/skills/run-rubygems-org/smoke.sh
```

That single command:

1. Probes Postgres (`:5432`), Memcached (`:11211`), and OpenSearch (`:9200`). If a service is already listening (native brew/apt install, or some other running container), it's left alone. If something is down and `docker compose` + `docker-compose.yml` are both available, it falls back to `docker compose up -d <service>`. If neither path works, it fails with the exact install commands to run.
2. If nothing is on :3000, launches `bundle exec rails server -p 3000 -b 127.0.0.1` under `nohup` (pid → `tmp/run-skill/rails.pid`, log → `tmp/run-skill/rails.log`). Otherwise reuses the existing server.
3. Polls `GET /` until it returns 200 (timeout 60s — cold start is ~3s here, ~10–15s on first boot after a code change due to Tailwind compile).
4. Curls four endpoints and fails loudly on any non-200 or missing-substring:
   - `/` (homepage HTML)
   - `/api/v1/gems/rubygem0.json` (gem JSON API)
   - `/versions` (compact_index — what `bundle` and `gem` fetch)
   - `/gems/rubygem0` (gem detail page)
5. Screenshots three pages with headless Chrome at 1280px wide → `tmp/run-skill/{home,gem,signin}.png`.

`rubygem0` exists because `db:seed` creates it; if you've wiped the DB, re-run `bin/rails db:seed`.

To stop a server `smoke.sh` started:

```bash
kill "$(cat tmp/run-skill/rails.pid)"
```

## Run (human path)

```bash
bin/rails s                  # foreground on :3000
```

Opens nothing — just listens. Useless headless; for an agent driving the app, always use `smoke.sh` so you get the screenshots and HTTP assertions.

## When this skill fails (learn-and-teach loop)

This skill keeps a running [`LEARNINGS.md`](LEARNINGS.md) so each failure becomes a one-time cost, not a recurring one. **When `smoke.sh` fails with something not already in the Troubleshooting table:**

1. **Read [`LEARNINGS.md`](LEARNINGS.md) first** — Ctrl-F your error string; someone may have already solved it.
2. **Read `tmp/run-skill/diagnostic.txt`** — `smoke.sh` writes a structured environment snapshot (ports, docker state, rails log tail, ruby/bundle versions) every time it fails.
3. **Fix it.** Capture the exact command(s) that worked.
4. **Add an entry to [`LEARNINGS.md`](LEARNINGS.md)** using the template at the top of that file. Don't skip this even if the fix is "obvious" to you — it won't be obvious to the next agent in a fresh container at 3am.
5. **Graduate stable fixes.** If the failure mode is likely to recur (not a one-off environment quirk):
   - Add a row to the **Troubleshooting** table below (symptom → fix), and/or
   - Update `smoke.sh` to auto-detect or auto-recover (e.g. add a probe, extend the docker fallback)
   - Then mark the LEARNINGS.md entry **Status: graduated** with a link to your commit/PR.

This is the skill teaching itself. `LEARNINGS.md` is the *why* behind every `SKILL.md` / `smoke.sh` change — keep it even after graduation.

## Tests

```bash
bin/rails test                                  # unit/integration
bin/rails test test/models/rubygem_test.rb:42   # single test
DB_HOST=localhost bin/rails test                # ONLY when not on the default unix-socket path — see Gotchas
bin/rails test:system                           # Playwright + Chrome
bin/ci                                          # full CI suite (lint + brakeman + tests)
```

## Gotchas

- **`.env.local` is excluded in the test environment.** dotenv loads `.env.local` for development but not for test, so `DB_HOST` is unset there. The dev config defaults to a Unix socket (no `DB_HOST` needed) but **tests crash if Postgres isn't on the default socket path** — set `DB_HOST=localhost` inline when running tests against the Docker Postgres on TCP. See `config/database.yml` and `config/environments/test.rb`.
- **There is no `/up` endpoint.** Rails 8's default health check is not wired up; use `GET /` (homepage) as the readiness probe. `/up` returns 404.
- **First boot prints ~50 lines of Datadog APM/CI-Visibility noise** before "Listening on …". This is normal — `dd-trace-rb` autoloads in development. Don't mistake it for failure.
- **OpenSearch may report `status: yellow`.** That's expected for a single-node cluster; the smoke script only requires `_cluster/health` to respond, not be green.
- **Seeded gems are `rubygem0`/`rubygem1`/`rubygem2`,** not real gems. `/api/v1/gems/rails.json` returns "This rubygem could not be found." — use `rubygem0` in any smoke check.
- **Tailwind runs in a separate process** (`bin/rails tailwindcss:watch` is auto-spawned in dev). It writes CSS asynchronously after boot; if the homepage looks unstyled in a screenshot, give it 2–3 more seconds.
- **`bin/setup` is destructive of dev DB schema.** It runs `db:prepare` which will create+migrate. To load real anonymized data, use `script/load-pg-dump` (see AGENTS.md).
- **The Playwright Chromium path is version-pinned.** `smoke.sh` globs `~/Library/Caches/ms-playwright/chromium-*/` so it survives upgrades, but if you blow away that cache, re-run `bin/playwright install --with-deps chromium`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `could not connect to server: Connection refused` (psql/Rails) | Postgres isn't running. Docker: `docker compose up -d db`. Native (macOS): `brew services start postgresql@14`. |
| `Faraday::ConnectionFailed` against `localhost:9200` | OpenSearch is down or still booting. `smoke.sh` will auto-start it via docker if available — otherwise see the OpenSearch `docker run` line in Prerequisites. Wait ~5s for `/_cluster/health` to respond. |
| `smoke.sh` fails: `<svc> is not responding ... docker compose isn't available here` | The probe found nothing on the port AND there's no docker on PATH. The error message lists the exact native-install command for that service — run it, then re-run `smoke.sh`. |
| `Address already in use - bind(2) for "127.0.0.1" port 3000` | A previous Rails is still alive: `pkill -f 'puma.*3000'` (or `kill $(cat tmp/run-skill/rails.pid)` if `smoke.sh` started it). |
| Smoke says `homepage never returned 200 (last 500)` | `tail -100 tmp/run-skill/rails.log` — usually a missing migration (`bin/rails db:migrate`) or DB seed (`bin/rails db:seed`). |
| Smoke says `gem JSON API failed (expected 200, got 404)` | DB is fresh and unseeded: `bin/rails db:seed` recreates `rubygem0`. |
| `no chromium found` in smoke output | `bin/playwright install --with-deps chromium`. The smoke script falls back to `/Applications/Google Chrome.app` if present. |
| Screenshot is blank/white | Server returned 200 but the page errored client-side; open `tmp/run-skill/rails.log` and look for the request just before — Tailwind not ready yet is the most common cause. Re-run `smoke.sh`. |
