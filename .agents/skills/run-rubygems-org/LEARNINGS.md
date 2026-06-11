# Learnings: running rubygems.org locally

A running log of failure modes encountered while bringing up rubygems.org and the fixes that worked. **This file exists so the skill can learn.** When `smoke.sh` fails:

1. **Read this file first** — someone may have already solved it (Ctrl-F your error string).
2. **Read `tmp/run-skill/diagnostic.txt`** — `smoke.sh` writes a structured snapshot of the environment whenever it fails (ports, docker state, rails log tail, ruby/bundle versions).
3. **Fix the issue.** Note the exact command(s) that worked.
4. **Add an entry below.** Use the template. Be specific — future-you / future-agent reads this cold and needs to act on it.
5. **Graduate stable fixes.** If the failure is likely to recur (not a one-off environment quirk), do one or both:
   - Add a row to `SKILL.md` > Troubleshooting (symptom → fix).
   - Update `smoke.sh` to auto-detect or auto-recover.
   - Then mark the entry below "**Status:** graduated" with a link to the commit/PR.

Don't skip step 4 even if you graduated immediately — this file is the *why* behind the SKILL changes.

## Entry template

Copy this block to the top of "Entries" and fill it in:

```markdown
## YYYY-MM-DD — short title

**Environment:** macOS arm64 14.5 / Ubuntu 22.04 / Linux container / etc.
**Triggered by:** `./.agents/skills/run-rubygems-org/smoke.sh` (or the specific command, if narrower)
**Symptom:** one-line error + where it appeared (stderr, `tmp/run-skill/rails.log`, `tmp/run-skill/diagnostic.txt`)
**Root cause:** the actual reason (not just the surface error)
**Fix:** the exact command(s) that worked, in order
**Status:** in-the-wild  |  graduated (link to commit/PR)
```

## Entries

_Add new entries at the top so the most recent is easiest to find._

## 2026-06-11 — native Postgres rejects `db:prepare` with password auth

**Environment:** Linux container (Ubuntu 24.04, fresh cloud agent sandbox), Postgres 16 via apt
**Triggered by:** `bin/setup` (step `bin/rails db:prepare`)
**Symptom:** `PG::ConnectionBad: ... FATAL: password authentication failed for user "postgres"` on stderr — *after* the development DB had already been created successfully.
**Root cause:** `db:prepare` prepares dev *and* test, and `config/database.yml` expects different passwords for the same `postgres` role (`devpassword` vs `testpassword`). Only a server that doesn't check passwords can satisfy both. Docker's `POSTGRES_HOST_AUTH_METHOD=trust` and Homebrew's default local `trust` do; apt's default `scram-sha-256` doesn't.
**Fix:** set the local/`127.0.0.1` entries in `pg_hba.conf` to `trust` (`sed -i 's/scram-sha-256/trust/g; s/peer$/trust/' "$(sudo -u postgres psql -tAc 'SHOW hba_file')"`), restart Postgres, re-run `bin/setup`.
**Status:** graduated (#6546 — Prerequisites trap + Troubleshooting row in SKILL.md)

## 2026-06-11 — `mise install` Ruby not picked up in non-interactive shells

**Environment:** Linux container (Ubuntu 24.04, fresh cloud agent sandbox), system Ruby 3.3.6, mise 2026.6.2
**Triggered by:** `bin/setup` right after `mise install`
**Symptom:** bundler aborts with a Ruby version mismatch (Gemfile wants 4.0.x, got 3.3.6), even though `mise install` reported `ruby 4.0.5 ✓ installed`.
**Root cause:** mise only rewrites PATH in shells where it's activated (shell rc hook). Agent/CI shells are non-interactive, so the freshly installed Ruby never shadows the system one.
**Fix:** `eval "$(mise activate bash --shims)"` before running anything, or prefix each command with `mise exec --`.
**Status:** graduated (#6546 — Prerequisites trap + Troubleshooting row in SKILL.md)

## 2026-06-11 — Docker Hub unauthenticated pull rate limit

**Environment:** Linux container (Ubuntu 24.04, fresh cloud agent sandbox — shared egress IP)
**Triggered by:** `docker compose up -d db cache search`
**Symptom:** `error from registry: You have reached your unauthenticated pull rate limit` on stderr; persisted across retries with backoff.
**Root cause:** Docker Hub rate-limits anonymous pulls per source IP; cloud sandboxes and CI runners share egress IPs, so a fresh environment can be rate-limited before its first pull.
**Fix:** pulled OpenSearch from the AWS mirror instead — `docker run -d -p 127.0.0.1:9200:9200 -e discovery.type=single-node -e DISABLE_SECURITY_PLUGIN=true -e 'OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m' public.ecr.aws/opensearchproject/opensearch:2.13.0` — and installed Postgres + memcached via apt (see the Postgres trust-auth entry above).
**Status:** graduated (#6546 — Troubleshooting row in SKILL.md)
