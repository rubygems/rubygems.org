# RubyGems.org

The Ruby community's gem host — a Ruby on Rails app (internal name: `gemcutter`).

## Stack

- Ruby 4.0.x (`.ruby-version`), Rails 8.1, Bundler/RubyGems 4.0.x
- PostgreSQL (>= 14), OpenSearch 2.13.0, Memcached — all required to run app & tests
- Chrome + Playwright for system tests

## Setup

Backing services run via Docker by default. If Docker isn't installed, see
[CONTRIBUTING.md](CONTRIBUTING.md#setting-up-the-environment) for native install
instructions (brew on macOS, apt on Debian/Ubuntu).

```bash
docker compose up        # starts postgres, opensearch, memcached (NOT the app)
bin/setup                # deps, db:prepare, db:seed, playwright, assets
```

## Developer data

Seed real data beyond `db:seed` (against the dev DB):

```bash
# Weekly anon prod DB dump (-c downloads latest from S3; DROPS & recreates the DB)
script/load-pg-dump -c -d rubygems_development ~/Downloads/public_postgresql.tar

# Import .gem files via the push pipeline (the "gem-author" user is created by db:seed)
bundle exec rake "gemcutter:import:process[vendor/cache,gem-author]"
bundle exec rake gemcutter:index:update   # rebuild the gem specs index (compact index / specs.*.gz) after importing
bundle exec rake searchkick:reindex CLASS=Rubygem   # rebuild the OpenSearch search index (separate from the gem index)
```

Dumps: <https://rubygems.org/pages/data>. Drop `-c` to load an already-downloaded file.

## Commands

```bash
bin/rails s            # run the app on :3000
bin/rails test:all     # all tests (unit + system)
bin/rails test         # non-system tests
bin/rails test test/models/rubygem_test.rb:42   # single file / line
bin/rails test -n /pattern/                     # tests matching name pattern
bin/rails test:system  # system tests (Playwright/Chrome)
bin/ci             # full CI suite locally (config/ci.rb)
```

**`DB_HOST`:**

- Standard install: defaults to the local Postgres socket — no setup needed.
- Network host (e.g. dev containers): must be set. dotenv excludes `.env.local`
  in the test env, so set it inline:

```bash
DB_HOST=db rails test   # only when Postgres isn't local
```

Team members with 1Password access can prefix any command with `script/dev` to
load dev secrets — see [CONTRIBUTING.md](CONTRIBUTING.md#developing-with-dev-secrets).

## Lint & security (CI will fail otherwise)

All of these run as part of `bin/ci`; reach for them individually when iterating.

```bash
bin/rubocop              # Ruby style
bin/herb analyze         # ERB linting
bin/prettier             # JS style
rake format              # auto-fix Ruby + JS
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/importmap audit      # JS dependency vulnerability audit
```

## Architecture (`app/`)

- **Dual interface**: the website (HTML controllers in `controllers/`) and the gem-client
  API (`controllers/api/v1`, `controllers/api/v2`, plus compact_index endpoints
  `/versions`, `/info/:gem_name`, `/names` that `bundle`/`gem` fetch).
- `models/`, `controllers/`, `views/` — standard Rails
- `components/` — ViewComponent UI components
- `policies/` — Pundit authorization
- `jobs/` — background jobs (GoodJob + Shoryuken/SQS)
- `avo/` — Avo admin interface
- `tasks/` — maintenance_tasks (data migrations)
- Frontend: Propshaft + importmap (no JS bundler), Stimulus controllers in
  `app/javascript/controllers/`, Tailwind CSS.
- Feature flags via Flipper (`flipper-active_record`; UI at `/features`).
- Auth via Clearance. Gem processing stores files in S3 (prod) or `server/` (dev).
- `lib/compact_index*`, `lib/rstuf*`, `lib/gemcutter` — gem index, TUF signing, core domain

## Testing

- Minitest with `shoulda-context` (`class FooTest < ActiveSupport::TestCase`, `should` blocks) + `shoulda-matchers`.
- `factory_bot` for test data (`create(:rubygem)`) — not fixtures; factories in `test/factories/`.
- `mocha` for mocking; system tests use Capybara + Playwright.
- `test/` mirrors `app/`. **Contributions are not accepted without tests.**

## Guardrails

- Gems are **yanked, never hard-deleted**: yanking creates a `Deletion` and sets the version `indexed: false`.
- Security-sensitive subsystems — change only with extra care and thorough tests:
  - **Auth & sessions** — Clearance (`app/models/user.rb`)
  - **MFA** — TOTP + WebAuthn (`app/models/concerns/user_*_methods.rb`, `webauthn_*.rb`)
  - **API keys & scopes** — `api_key.rb`, `api_key_rubygem_scope.rb` (push/yank/etc. permissions)
  - **Trusted publishing (OIDC)** — keyless publishing via `app/models/oidc/**` (e.g. GitHub Actions); access policies & token exchange
  - **Gem push pipeline** — `app/models/pusher.rb` (validates & ingests uploaded gems)
  - **Ownership** — `app/models/ownership.rb` (who may push/yank a gem)
  - **Attestations / provenance** — `app/models/attestation.rb`, Sigstore cert chain
  - **TUF signing** — `lib/rstuf*`
- Never commit secrets or production data; use the [dev-secrets workflow](CONTRIBUTING.md#developing-with-dev-secrets).

## Conventions

- master must stay fast-forwardable; branch off it for every change.
- Run `bin/ci` locally before pushing — it mirrors CI (lint, security, tests).
- User-facing strings: add keys to `config/locales/en.yml`, then run `bin/fill-locales` to propagate to other locales.
