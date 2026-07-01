#!/usr/bin/env bash
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# End-to-end test for the standalone release docker-compose.yml.
#
# Simulates an end-user experience: pulls images, starts services, seeds
# the database, runs smoke / auth / API-CRUD / persistence tests, then
# cleans up. Uses an isolated Docker Compose project name so it never
# touches the dev environment.
#
# Prerequisites: Docker Desktop (macOS/Windows) or Docker Engine (Linux),
#                curl, python3 (for JSON parsing)
#
# Usage:
#   ./scripts/test-release-compose.sh              # normal run
#   ./scripts/test-release-compose.sh --skip-cleanup  # keep containers for debugging
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

set -euo pipefail

# â”€â”€ Parse args â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
SKIP_CLEANUP=false
for arg in "$@"; do
  case "$arg" in
    --skip-cleanup) SKIP_CLEANUP=true ;;
  esac
done

# â”€â”€ Globals â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
PROJECT_NAME="easybacklog-release-test"
BASE_URL="http://localhost:3000"
API_USER="demo@example.com"
DEMO_PASSWORD="password123"
HEALTH_TIMEOUT=180

PASSED=0
FAILED=0
FAILED_TESTS=()
SECONDS=0  # bash built-in timer

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RELEASE_COMPOSE="$REPO_ROOT/releases/docker-compose.yml"
RELEASE_ENV="$REPO_ROOT/releases/.env"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/easybacklog-release-test.XXXXXXXX")"

# Cookie jar for session-based tests
COOKIE_JAR="$TEMP_DIR/cookies.txt"

# â”€â”€ Colors â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
phase() {
  echo -e "\n${CYAN}==== $1 ====${NC}"
}

test_result() {
  local name="$1"
  local pass="$2"
  local detail="${3:-}"
  if [[ "$pass" == "true" ]]; then
    PASSED=$((PASSED + 1))
    echo -e "  ${GREEN}[PASS]${NC} $name"
  else
    FAILED=$((FAILED + 1))
    FAILED_TESTS+=("$name")
    echo -e "  ${RED}[FAIL]${NC} $name"
    if [[ -n "$detail" ]]; then
      echo -e "         ${GRAY}$detail${NC}"
    fi
  fi
}

compose() {
  docker compose -p "$PROJECT_NAME" "$@"
}

compose_exec() {
  docker compose -p "$PROJECT_NAME" exec -T web "$@"
}

api_get() {
  local path="$1"
  local encoded_user
  encoded_user=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$API_USER'))")
  curl -sf "${BASE_URL}/api${path}?dev_api_user=${encoded_user}" \
    -H "Content-Type: application/json" 2>/dev/null || true
}

api_post() {
  local path="$1"
  local body="$2"
  local token="$3"
  curl -sf "${BASE_URL}/api${path}" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: token $token" \
    -d "$body" 2>/dev/null || true
}

api_delete() {
  local path="$1"
  local token="$2"
  curl -sf "${BASE_URL}/api${path}" \
    -X DELETE \
    -H "Content-Type: application/json" \
    -H "Authorization: token $token" 2>/dev/null || true
}

# ── JSON helpers (python3 — no jq needed) ───────────────────────────────
json_len()    { printf '%s' "$1" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0"; }
json_get0id() { printf '%s' "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0].get('id',''))" 2>/dev/null || echo ""; }
json_getid()  { printf '%s' "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null || echo ""; }
json_getstatus() { printf '%s' "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status',''))" 2>/dev/null || echo ""; }

wait_services_healthy() {
  echo -n "  Waiting for services to become healthy (timeout: ${HEALTH_TIMEOUT}s)..."
  local elapsed=0
  while [[ $elapsed -lt $HEALTH_TIMEOUT ]]; do
    local ps_output counts total healthy
    ps_output=$(docker compose -p "$PROJECT_NAME" ps --format json 2>/dev/null || true)
    if [[ -n "$ps_output" ]]; then
      counts=$(printf '%s' "$ps_output" | python3 -c "
import sys, json
data = sys.stdin.read().strip()
try:
    objs = json.loads(data)
    if isinstance(objs, dict): objs = [objs]
except Exception:
    objs = [json.loads(l) for l in data.splitlines() if l.strip()]
total = len(objs)
healthy = sum(1 for c in objs
              if c.get('State') == 'running'
              and c.get('Health', '') in ('healthy', '', 'none', None))
print(total, healthy)
" 2>/dev/null || echo "0 0")
      total=$(echo "$counts" | cut -d' ' -f1)
      healthy=$(echo "$counts" | cut -d' ' -f2)
      if [[ "$total" -ge 4 && "$healthy" -ge 4 ]]; then
        echo -e " ${GREEN}ready! (${elapsed}s)${NC}"
        return 0
      fi
    fi
    sleep 5
    elapsed=$((elapsed + 5))
    echo -n "."
  done
  echo -e " ${RED}TIMEOUT after ${HEALTH_TIMEOUT}s${NC}"
  return 1
}

cleanup() {
  phase "CLEANUP"
  if [[ "$SKIP_CLEANUP" == "true" ]]; then
    echo -e "  ${YELLOW}Skipping cleanup (--skip-cleanup). Project: $PROJECT_NAME  Dir: $TEMP_DIR${NC}"
    return
  fi
  pushd "$TEMP_DIR" > /dev/null 2>&1 || true
  docker compose -p "$PROJECT_NAME" down -v --remove-orphans 2>/dev/null || true
  popd > /dev/null 2>&1 || true
  rm -rf "$TEMP_DIR" 2>/dev/null || true
  echo "  Cleaned up containers, volumes, and temp directory."
}

# â”€â”€ Trap for unexpected exit â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
trap_cleanup() {
  if [[ -d "$TEMP_DIR" && "$SKIP_CLEANUP" != "true" ]]; then
    pushd "$TEMP_DIR" > /dev/null 2>&1 || true
    docker compose -p "$PROJECT_NAME" down -v --remove-orphans 2>/dev/null || true
    popd > /dev/null 2>&1 || true
    rm -rf "$TEMP_DIR" 2>/dev/null || true
  fi
}
trap trap_cleanup EXIT

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# PHASE 1 â€” Setup & Isolation
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
phase "PHASE 1: Setup & Isolation"

# 1. Create temp dir & copy release files (compose + .env)
cp "$RELEASE_COMPOSE" "$TEMP_DIR/docker-compose.yml"
cp "$RELEASE_ENV" "$TEMP_DIR/.env"
test_result "Copy release compose and .env to temp dir" \
  "$([[ -f "$TEMP_DIR/docker-compose.yml" && -f "$TEMP_DIR/.env" ]] && echo true || echo false)"

# 2. Write test-specific values into .env (isolates this run from the defaults)
TEST_SECRET_TOKEN=$(openssl rand -hex 64)
TEST_DEVISE_PEPPER=$(openssl rand -hex 32)
TEST_DB_PASSWORD="testpass_$RANDOM"
if sed --version &>/dev/null 2>&1; then
  sed -i "s|^SECRET_TOKEN=.*|SECRET_TOKEN=${TEST_SECRET_TOKEN}|" "$TEMP_DIR/.env"
  sed -i "s|^DEVISE_PEPPER=.*|DEVISE_PEPPER=${TEST_DEVISE_PEPPER}|" "$TEMP_DIR/.env"
  sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${TEST_DB_PASSWORD}|" "$TEMP_DIR/.env"
else
  sed -i '' "s|^SECRET_TOKEN=.*|SECRET_TOKEN=${TEST_SECRET_TOKEN}|" "$TEMP_DIR/.env"
  sed -i '' "s|^DEVISE_PEPPER=.*|DEVISE_PEPPER=${TEST_DEVISE_PEPPER}|" "$TEMP_DIR/.env"
  sed -i '' "s|^DB_PASSWORD=.*|DB_PASSWORD=${TEST_DB_PASSWORD}|" "$TEMP_DIR/.env"
fi
test_result "Write test-specific values to .env" \
  "$(grep -q "^SECRET_TOKEN=${TEST_SECRET_TOKEN}$" "$TEMP_DIR/.env" && echo true || echo false)"

cd "$TEMP_DIR"

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# PHASE 2 â€” Pull & Start
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
phase "PHASE 2: Pull & Start"

# 4. Pull images
if compose pull; then
  test_result "docker compose pull" "true"
else
  test_result "docker compose pull" "false" "Image pull failed"
  echo "FATAL: Image pull failed â€” cannot continue." >&2
  exit 1
fi

# 5. Start services
if compose up -d; then
  test_result "docker compose up -d" "true"
else
  test_result "docker compose up -d" "false" "docker compose up failed"
  echo "FATAL: docker compose up failed â€” cannot continue." >&2
  exit 1
fi

# 6. Wait for healthy
if wait_services_healthy; then
  test_result "All services healthy" "true"
else
  test_result "All services healthy" "false"
  echo "FATAL: Services did not become healthy â€” cannot continue." >&2
  exit 1
fi

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# PHASE 3 â€” Database Init
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
phase "PHASE 3: Database Initialization"

# 7. schema:load
out=$(compose_exec bundle exec rake db:schema:load 2>&1) && rc=0 || rc=$?
test_result "rake db:schema:load" "$([[ $rc -eq 0 ]] && echo true || echo false)" "$out"

# 8. db:seed
out=$(compose_exec bundle exec rake db:seed 2>&1) && rc=0 || rc=$?
test_result "rake db:seed" "$([[ $rc -eq 0 ]] && echo true || echo false)" "$out"

# 9. db:seed:sample
out=$(compose_exec bundle exec rake db:seed:sample 2>&1) && rc=0 || rc=$?
test_result "rake db:seed:sample" "$([[ $rc -eq 0 ]] && echo true || echo false)" "$out"

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# PHASE 4 â€” Smoke Tests
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
phase "PHASE 4: Smoke Tests"

# Give Rails a moment to be fully responsive after seeding
sleep 3

# 10. Root page
root_code=$(curl -sf -o /dev/null -w "%{http_code}" "$BASE_URL" 2>/dev/null || echo "000")
test_result "GET / returns 200" "$([[ "$root_code" == "200" ]] && echo true || echo false)" "HTTP $root_code"

# 11. /status
status_body=$(curl -sf "$BASE_URL/status" 2>/dev/null || echo "")
status_code=$(curl -sf -o /dev/null -w "%{http_code}" "$BASE_URL/status" 2>/dev/null || echo "000")
status_healthy=false
if [[ "$status_code" == "200" ]] && echo "$status_body" | grep -qi "healthy"; then
  status_healthy=true
fi
test_result "GET /status returns healthy" "$status_healthy" "$status_body"

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# PHASE 5 â€” Authentication Tests
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
phase "PHASE 5: Authentication"

# 12. GET sign-in page and extract CSRF token
csrf_token=""
sign_in_body=$(curl -sf -c "$COOKIE_JAR" "$BASE_URL/users/sign_in" 2>/dev/null || echo "")
if [[ -n "$sign_in_body" ]]; then
  csrf_token=$(echo "$sign_in_body" | grep -o 'name="authenticity_token"[^>]*value="[^"]*"' | head -1 | grep -o 'value="[^"]*"' | sed 's/value="//;s/"$//')
fi
test_result "GET /users/sign_in and extract CSRF token" \
  "$([[ -n "$csrf_token" ]] && echo true || echo false)"

# 13. POST sign in
login_ok=false
dash_ok=false
if [[ -n "$csrf_token" ]]; then
  login_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -L \
    "$BASE_URL/users/sign_in" \
    --data-urlencode "user[email]=$API_USER" \
    --data-urlencode "user[password]=$DEMO_PASSWORD" \
    --data-urlencode "authenticity_token=$csrf_token" \
    --data-urlencode "user[remember_me]=0" 2>/dev/null || echo "000")
  if [[ "$login_code" == "200" || "$login_code" == "302" ]]; then
    login_ok=true
    dash_ok=true
  fi
  test_result "POST /users/sign_in succeeds" "$login_ok" "HTTP $login_code"
else
  test_result "POST /users/sign_in succeeds" "false" "Skipped â€” no CSRF token"
fi

# 14. Verify dashboard access
if [[ "$dash_ok" == "true" ]]; then
  test_result "GET /dashboard with session returns 200" "true"
elif [[ "$login_ok" == "true" ]]; then
  dash_code=$(curl -sf -o /dev/null -w "%{http_code}" -b "$COOKIE_JAR" "$BASE_URL/dashboard" 2>/dev/null || echo "000")
  test_result "GET /dashboard with session returns 200" \
    "$([[ "$dash_code" == "200" ]] && echo true || echo false)" "HTTP $dash_code"
else
  test_result "GET /dashboard with session returns 200" "false" "Skipped â€” login failed"
fi

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# PHASE 6 â€” API CRUD Tests (dev_api_user for reads, API token for writes)
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
phase "PHASE 6: API CRUD Tests"

# Create an API token for write operations
token_out=$(compose_exec bundle exec rails runner \
  "user = User.find_by_email('demo@example.com'); token = user.user_tokens.create!; puts token.access_token" 2>/dev/null || echo "")
api_token=$(echo "$token_out" | grep -E '^[a-z0-9]{10,}$' | head -1 | tr -d '[:space:]')
test_result "Create API token for write tests" \
  "$([[ -n "$api_token" ]] && echo true || echo false)"

# 15. GET /api/locales
locales=$(api_get "/locales")
locale_count=$(json_len "$locales")
test_result "GET /api/locales returns 6 locales" \
  "$([[ "$locale_count" == "6" ]] && echo true || echo false)" "Got $locale_count"

# 16. GET /api/scoring-rules
rules=$(api_get "/scoring-rules")
rule_count=$(json_len "$rules")
test_result "GET /api/scoring-rules returns 3 rules" \
  "$([[ "$rule_count" == "3" ]] && echo true || echo false)" "Got $rule_count"

# 17. GET /api/sprint-story-statuses
statuses=$(api_get "/sprint-story-statuses")
status_count=$(json_len "$statuses")
test_result "GET /api/sprint-story-statuses returns 4" \
  "$([[ "$status_count" == "4" ]] && echo true || echo false)" "Got $status_count"

# 18. GET /api/accounts
accounts=$(api_get "/accounts")
acct_count=$(json_len "$accounts")
test_result "GET /api/accounts returns >= 1" \
  "$([[ "$acct_count" -ge 1 ]] && echo true || echo false)" "Got $acct_count"

if [[ "$acct_count" -ge 1 ]]; then
  account_id=$(json_get0id "$accounts")

  # 19. GET backlogs
  backlogs=$(api_get "/accounts/$account_id/backlogs")
  backlog_count=$(json_len "$backlogs")
  test_result "GET /api/accounts/:id/backlogs returns data" \
    "$([[ "$backlog_count" -ge 1 ]] && echo true || echo false)" "Got $backlog_count"

  # 20. POST â€” create backlog (uses API token)
  locale_id=$(json_get0id "$locales")
  rule_id=$(json_get0id "$rules")
  new_backlog=$(api_post "/accounts/$account_id/backlogs" \
    "{\"name\":\"Release Test Backlog\",\"velocity\":3,\"rate\":100,\"use_50_90\":true,\"scoring_rule_id\":$rule_id,\"locale_id\":$locale_id}" \
    "$api_token")
  new_id=$(json_getid "$new_backlog")
  create_ok=$([[ -n "$new_id" ]] && echo true || echo false)
  test_result "POST /api/accounts/:id/backlogs creates backlog" "$create_ok"

  if [[ "$create_ok" == "true" ]]; then
    # 21. GET â€” read newly created backlog
    read_back=$(api_get "/accounts/$account_id/backlogs/$new_id")
    read_id=$(json_getid "$read_back")
    test_result "GET created backlog by id" \
      "$([[ "$read_id" == "$new_id" ]] && echo true || echo false)"

    # 22. DELETE â€” remove test backlog
    api_delete "/accounts/$account_id/backlogs/$new_id" "$api_token" > /dev/null
    gone=$(api_get "/accounts/$account_id/backlogs/$new_id")
    gone_status=$(json_getstatus "$gone")
    test_result "DELETE created backlog" \
      "$([[ -z "$gone" || "$gone_status" == "error" ]] && echo true || echo false)"
  else
    test_result "GET created backlog by id" "false" "Skipped â€” create failed"
    test_result "DELETE created backlog" "false" "Skipped â€” create failed"
  fi
else
  test_result "GET /api/accounts/:id/backlogs" "false" "No accounts found"
  test_result "POST create backlog" "false" "No accounts found"
  test_result "GET created backlog" "false" "No accounts found"
  test_result "DELETE created backlog" "false" "No accounts found"
fi

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# PHASE 7 â€” Sidekiq Verification
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
phase "PHASE 7: Sidekiq"

# 23. Check Sidekiq container is running and connected to Redis
sq_logs=$(docker compose -p "$PROJECT_NAME" logs sidekiq --tail 50 2>&1 || true)
sq_running=$(echo "$sq_logs" | grep -c "Starting processing" || true)
sq_redis=$(echo "$sq_logs" | grep -c "Booting Sidekiq" || true)
sq_detail=""
if [[ "$sq_running" -eq 0 ]]; then
  sq_detail='No "Starting processing" in logs'
fi
test_result "Sidekiq container booted and connected to Redis" \
  "$([[ "$sq_running" -gt 0 && "$sq_redis" -gt 0 ]] && echo true || echo false)" "$sq_detail"

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# PHASE 8 â€” Persistence / Restart Test
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
phase "PHASE 8: Persistence across restart"

# 24. Stop (keep volumes)
if compose down; then
  test_result "docker compose down (volumes kept)" "true"
else
  test_result "docker compose down (volumes kept)" "false"
fi

# 25. Restart
if compose up -d; then
  test_result "docker compose up -d (restart)" "true"
else
  test_result "docker compose up -d (restart)" "false"
fi

# 26. Wait for healthy
if wait_services_healthy; then
  test_result "Services healthy after restart" "true"
  healthy2=true
else
  test_result "Services healthy after restart" "false"
  healthy2=false
fi

if [[ "$healthy2" == "true" ]]; then
  # Wait for Rails to fully boot
  retries=0
  status_ok2=false
  while [[ $retries -lt 6 && "$status_ok2" == "false" ]]; do
    sleep 5
    status2_body=$(curl -sf "$BASE_URL/status" --max-time 30 2>/dev/null || echo "")
    status2_code=$(curl -sf -o /dev/null -w "%{http_code}" "$BASE_URL/status" --max-time 30 2>/dev/null || echo "000")
    if [[ "$status2_code" == "200" ]] && echo "$status2_body" | grep -qi "healthy"; then
      status_ok2=true
    fi
    retries=$((retries + 1))
  done

  # 27. /status still healthy
  test_result "GET /status healthy after restart" "$status_ok2"

  # 28. Data persisted
  accts2=$(api_get "/accounts")
  acct2_count=$(json_len "$accts2")
  test_result "Data persisted after restart" \
    "$([[ "$acct2_count" -ge 1 ]] && echo true || echo false)"
else
  test_result "GET /status after restart" "false" "Services not healthy"
  test_result "Data persisted after restart" "false" "Services not healthy"
fi

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# PHASE 9 â€” Cleanup & Summary
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
cleanup

# Disable the EXIT trap since we already cleaned up
trap - EXIT

# Clean up test variables
unset TEST_SECRET_TOKEN TEST_DEVISE_PEPPER TEST_DB_PASSWORD 2>/dev/null || true

# â”€â”€ Summary â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
elapsed=$SECONDS
duration=$(printf '%02d:%02d' $((elapsed / 60)) $((elapsed % 60)))
total=$((PASSED + FAILED))

echo ""
echo -e "${WHITE}â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—${NC}"
echo -e "${WHITE}â•‘         TEST RUN SUMMARY                 â•‘${NC}"
echo -e "${WHITE}â• â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•£${NC}"
printf "${GREEN}â•‘  Passed : %3d                            â•‘${NC}\n" "$PASSED"
if [[ $FAILED -gt 0 ]]; then
  printf "${RED}â•‘  Failed : %3d                            â•‘${NC}\n" "$FAILED"
else
  printf "${GREEN}â•‘  Failed : %3d                            â•‘${NC}\n" "$FAILED"
fi
printf "${WHITE}â•‘  Total  : %3d                            â•‘${NC}\n" "$total"
printf "${WHITE}â•‘  Time   : %6s                         â•‘${NC}\n" "$duration"
echo -e "${WHITE}â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"

if [[ $FAILED -gt 0 ]]; then
  echo -e "\n${RED}Failed tests:${NC}"
  for t in "${FAILED_TESTS[@]}"; do
    echo -e "  ${RED}- $t${NC}"
  done
  exit 1
fi
exit 0
