#!/usr/bin/env bash
# Boot RubyGems.org locally and smoke-test it end-to-end.
# Used by the run-rubygems-org skill. Idempotent.
#
# Steps:
#   1. Ensure backing services are reachable on the standard ports
#      (postgres 5432, memcached 11211, opensearch 9200). Probe first; only
#      fall back to `docker compose up -d` if a service is down and docker
#      compose is available. Native installs (brew/apt) are supported —
#      whatever is listening on the port wins.
#   2. Start `rails s` on :3000 in the background if nothing is listening there.
#   3. Wait for the homepage to return 200.
#   4. Curl key endpoints (HTML + JSON API + compact_index).
#   5. Take headless-Chrome screenshots of the home page and a seeded gem page.
#
# Outputs:
#   - server log:   tmp/run-skill/rails.log
#   - server pid:   tmp/run-skill/rails.pid   (only when this script started it)
#   - screenshots:  tmp/run-skill/*.png
#
# Stop a server this script started:
#   kill "$(cat tmp/run-skill/rails.pid)"

set -euo pipefail

# Always run from the repo root, regardless of CWD.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$REPO_ROOT"

OUT_DIR="tmp/run-skill"
DIAG_FILE="$OUT_DIR/diagnostic.txt"
LEARNINGS_REL=".agents/skills/run-rubygems-org/LEARNINGS.md"
mkdir -p "$OUT_DIR"

step() { printf '\n=== %s ===\n' "$*"; }

# Pure-bash TCP probe — no `nc`/`pg_isready`/`psql` dependency.
# Hoisted above fail() so dump_diagnostics can use it.
port_open() { (exec 3<>"/dev/tcp/$1/$2") 2>/dev/null && return 0 || return 1; }

# Write a structured snapshot of the environment to $DIAG_FILE so the agent
# investigating a failure has one file to read instead of running 5 probes.
dump_diagnostics() {
  {
    echo "=== diagnostic dump @ $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
    echo "host:    $(uname -a)"
    echo "pwd:     $(pwd)"
    echo "ruby:    $(ruby -v 2>&1 || echo MISSING)"
    echo "bundle:  $(bundle -v 2>&1 || echo MISSING)"
    echo "docker:  $(docker --version 2>&1 || echo MISSING)"
    echo
    echo "--- backing-service ports ---"
    for p in 3000 5432 9200 11211; do
      port_open 127.0.0.1 "$p" 2>/dev/null && echo "  :$p OPEN" || echo "  :$p closed"
    done
    echo
    echo "--- opensearch /_cluster/health (if reachable) ---"
    curl -s -m 2 http://127.0.0.1:9200/_cluster/health 2>&1 || echo "(unreachable)"
    echo
    echo "--- docker compose ps ---"
    (docker compose ps 2>&1) || echo "(docker compose not available)"
    echo
    echo "--- rails log tail (last 80 lines) ---"
    tail -80 "$OUT_DIR/rails.log" 2>/dev/null || echo "(no rails.log)"
  } > "$DIAG_FILE" 2>&1
}

fail() {
  printf '\n!!! %s\n' "$*" >&2
  dump_diagnostics
  cat >&2 <<EOF

→ Diagnostic snapshot written to: $DIAG_FILE
→ If you figure out a fix that's NOT in SKILL.md > Troubleshooting,
  append it to: $LEARNINGS_REL
  (entry template is at the top of that file). The next agent will benefit.
EOF
  exit 1
}

# ---------------------------------------------------------------------------
# 1. backing services
#
# Probe first, start later. If a service is already listening (native install
# via brew/apt, or someone else's docker), don't touch it. Only fall back to
# `docker compose up -d` for services that are down AND defined in this
# repo's docker-compose.yml AND a usable docker is available.
# ---------------------------------------------------------------------------
step "backing services"

probe_pg() { port_open 127.0.0.1 5432; }
probe_mc() { port_open 127.0.0.1 11211; }
probe_os() { curl -sf -m 2 http://127.0.0.1:9200/_cluster/health >/dev/null; }

# Decide whether docker compose is a viable fallback for a given service.
HAVE_DOCKER=n
if command -v docker >/dev/null && docker compose version >/dev/null 2>&1 \
   && [[ -f docker-compose.yml ]]; then
  HAVE_DOCKER=y
fi

bring_up() {
  local svc=$1 probe=$2 port=$3 docker_name=$4
  if $probe; then
    echo "  ${svc}: already up on :${port}"
    return 0
  fi
  if [[ "$HAVE_DOCKER" == y ]] && grep -q "^  ${docker_name}:" docker-compose.yml; then
    echo "  ${svc}: not responding on :${port}, starting via docker compose..."
    docker compose up -d "$docker_name" >/dev/null
    # 60s: OpenSearch in particular can take >30s to accept connections cold.
    for _ in $(seq 1 60); do $probe && { echo "  ${svc}: up"; return 0; }; sleep 1; done
    fail "${svc} never came up after docker compose up -d ${docker_name} (see: docker compose logs ${docker_name})"
  fi
  # No docker fallback: tell the user how to bring it up natively.
  fail "${svc} is not responding on :${port} and docker compose isn't available here.
        Start it natively, then re-run. See CONTRIBUTING.md > Development Setup for install steps:
          postgres   : brew services start postgresql   |  sudo systemctl start postgresql
          memcached  : brew services start memcached    |  sudo systemctl start memcached
          opensearch : docker run -p 9200:9200 -e discovery.type=single-node \\
                          -e DISABLE_SECURITY_PLUGIN=true opensearchproject/opensearch:2.13.0"
}

bring_up postgres   probe_pg 5432  db
bring_up memcached  probe_mc 11211 cache
bring_up opensearch probe_os 9200  search

# ---------------------------------------------------------------------------
# 2. rails server
# ---------------------------------------------------------------------------
started_server=0
# Reuse anything bound to :3000 — even if it currently 5xx's (e.g. pending
# migrations). Starting a second server would just fail with EADDRINUSE; let
# the readiness loop below decide whether it becomes healthy.
if port_open 127.0.0.1 3000; then
  step "rails already listening on :3000 (reusing)"
else
  step "starting rails s -p 3000"
  : > "$OUT_DIR/rails.log"
  # nohup so the puma process survives this shell exiting.
  nohup bundle exec rails server -p 3000 -b 127.0.0.1 >"$OUT_DIR/rails.log" 2>&1 &
  echo $! > "$OUT_DIR/rails.pid"
  started_server=1
  echo "  pid $(cat "$OUT_DIR/rails.pid"), log $OUT_DIR/rails.log"
fi

step "waiting for homepage to return 200 (up to 60s)"
for i in $(seq 1 60); do
  # curl -w already emits 000 on connection failure; don't `|| echo 000` or
  # the two concatenate into "000000".
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 5 http://127.0.0.1:3000/ || true)
  code=${code:-000}
  [[ "$code" == 200 ]] && { echo "  ready after ${i}s"; break; }
  sleep 1
done
[[ "$code" == 200 ]] || fail "homepage never returned 200 (last $code); tail -50 $OUT_DIR/rails.log"

# ---------------------------------------------------------------------------
# 3. http smoke checks
# ---------------------------------------------------------------------------
step "endpoint smoke checks"
check() {
  local name=$1 url=$2 expect=$3 substr=${4:-}
  local resp code body
  # `|| fail` so a connection-level curl error still writes diagnostics
  # instead of dying silently via set -e.
  resp=$(curl -sS -m 10 -w '\n__HTTP_CODE__%{http_code}' "$url") \
    || fail "$name: curl could not reach $url (server died? tail -50 $OUT_DIR/rails.log)"
  code=${resp##*__HTTP_CODE__}
  body=${resp%__HTTP_CODE__*}
  printf '  %-22s %s -> %s' "$name" "$url" "$code"
  [[ "$code" == "$expect" ]] || { echo " (expected $expect)"; fail "$name failed"; }
  if [[ -n "$substr" ]] && ! grep -qF "$substr" <<<"$body"; then
    echo " (missing substr '$substr')"; fail "$name body check failed"
  fi
  echo " ok"
}
check "homepage HTML"     http://127.0.0.1:3000/                          200 "RubyGems.org"
check "gem JSON API"      http://127.0.0.1:3000/api/v1/gems/rubygem0.json 200 '"name":"rubygem0"'
check "compact_index /versions" http://127.0.0.1:3000/versions            200 "rubygem0"
check "gem detail page"   http://127.0.0.1:3000/gems/rubygem0             200 "rubygem0"

# ---------------------------------------------------------------------------
# 4. screenshots
#
# bin/playwright is the Node CLI pinned to the playwright-ruby-client gem;
# `playwright screenshot` knows where its own bundled Chromium lives, so we
# don't have to. If the CLI isn't usable at all (no node / no bin/playwright),
# skip — screenshots are nice-to-have. But if the CLI exists and a shot fails
# (usually a missing Chromium), fail with the install command.
# ---------------------------------------------------------------------------
step "screenshots via playwright"
if ! command -v node >/dev/null || ! [[ -x bin/playwright ]]; then
  echo "  bin/playwright unavailable (need node + bin/playwright); skipping screenshots"
else
  shoot() {
    local name=$1 url=$2 wh=${3:-1280,1400}
    bin/playwright screenshot --browser=chromium --viewport-size="$wh" \
      "$url" "$OUT_DIR/$name.png" >/dev/null 2>&1 \
      || fail "screenshot $name failed (try: bin/playwright install --with-deps chromium)"
    [[ -s "$OUT_DIR/$name.png" ]] || fail "screenshot $name produced empty file"
    printf '  %-12s -> %s\n' "$name" "$OUT_DIR/$name.png"
  }
  shoot home    http://127.0.0.1:3000/                  1280,1600
  shoot gem     http://127.0.0.1:3000/gems/rubygem0     1280,1400
  shoot signin  http://127.0.0.1:3000/sign_in           1280,1200
fi

step "done"
echo "  screenshots: $OUT_DIR/*.png"
if (( started_server )); then
  echo "  rails pid:   $(cat "$OUT_DIR/rails.pid")  (kill it when you're done)"
fi
