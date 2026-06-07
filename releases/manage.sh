#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════
# easyBacklog — Management Script (Linux / macOS)
#
# Usage:
#   ./manage.sh setup    — first-time setup: download files, start, init DB
#   ./manage.sh start    — start all services
#   ./manage.sh stop     — stop all services (data is kept)
#   ./manage.sh reset    — wipe data and reinitialise from scratch
#   ./manage.sh delete   — remove everything (containers, volumes, files)
#   ./manage.sh update   — pull latest images and restart
#   ./manage.sh status   — show container status
# ══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────
REPO_URL="https://github.com/mattanmr/easybacklog"
RELEASE_BASE="${REPO_URL}/releases/latest/download"
APP_URL="http://localhost:3000"

# ── Colors ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────
info()    { echo -e "${CYAN}  → $*${NC}"; }
success() { echo -e "${GREEN}  ✓ $*${NC}"; }
warn()    { echo -e "${YELLOW}  ! $*${NC}"; }
error()   { echo -e "${RED}  ✗ $*${NC}" >&2; }

confirm() {
  local prompt="$1"
  local answer
  read -r -p "$(echo -e "${YELLOW}  ? ${prompt} [y/N]: ${NC}")" answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

prompt_yn() {
  # prompt_yn "Question text" "Y"  → default yes
  # prompt_yn "Question text" "N"  → default no
  local prompt="$1"
  local default="${2:-N}"
  local display
  if [[ "$default" == "Y" ]]; then display="[Y/n]"; else display="[y/N]"; fi
  local answer
  read -r -p "$(echo -e "${CYAN}  ? ${prompt} ${display}: ${NC}")" answer
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[Yy]$ ]]
}

# ── Prerequisite checks ────────────────────────────────────────────────────
check_docker() {
  if ! command -v docker &>/dev/null; then
    error "Docker is not installed or not in PATH."
    echo -e "  Install Docker from: ${WHITE}https://docs.docker.com/get-docker/${NC}"
    exit 1
  fi
  if ! docker info &>/dev/null 2>&1; then
    error "Docker daemon is not running."
    echo    "  Please start Docker Desktop (or the Docker service) and try again."
    exit 1
  fi
}

# ── Download helper ────────────────────────────────────────────────────────
download_file() {
  local url="$1"
  local dest="$2"
  if command -v curl &>/dev/null; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget &>/dev/null; then
    wget -qO "$dest" "$url"
  else
    error "Neither curl nor wget is available. Install one and try again."
    exit 1
  fi
}

# ── Ensure release files are present ──────────────────────────────────────
ensure_files() {
  if [[ ! -f docker-compose.yml ]]; then
    info "Downloading docker-compose.yml..."
    download_file "${RELEASE_BASE}/docker-compose.yml" docker-compose.yml
    success "docker-compose.yml downloaded."
  fi
  if [[ ! -f .env ]]; then
    info "Downloading .env..."
    download_file "${RELEASE_BASE}/.env" .env
    success ".env downloaded."
  fi
}

# ── Wait for the app to become healthy ────────────────────────────────────
wait_healthy() {
  local timeout=180
  local elapsed=0
  info "Waiting for services to become healthy (up to ${timeout}s)..."
  while [[ $elapsed -lt $timeout ]]; do
    if curl -sf "${APP_URL}/status" 2>/dev/null | grep -qi "healthy"; then
      success "Application is ready at ${APP_URL}"
      return 0
    fi
    sleep 5
    elapsed=$((elapsed + 5))
    echo -n "."
  done
  echo ""
  error "Timed out waiting for the application to become healthy."
  echo    "  Run 'docker compose logs web' to diagnose."
  return 1
}

# ── Check if DB is already initialised ────────────────────────────────────
db_initialised() {
  local result
  result=$(docker compose exec -T web bundle exec rails runner \
    "puts ActiveRecord::Base.connection.tables.any?" 2>/dev/null || echo "false")
  [[ "$result" == *"true"* ]]
}

# ── Initialise the database ────────────────────────────────────────────────
init_db() {
  info "Loading database schema..."
  docker compose exec -T web bundle exec rake db:schema:load
  info "Seeding database..."
  docker compose exec -T web bundle exec rake db:seed
  success "Database initialised."

  if prompt_yn "Load sample data? (creates demo@example.com / password123)" "Y"; then
    info "Loading sample data..."
    docker compose exec -T web bundle exec rake db:seed:sample
    success "Sample data loaded."
    echo ""
    echo -e "  Demo credentials: ${WHITE}demo@example.com${NC} / ${WHITE}password123${NC}"
  fi
}

# ════════════════════════════════════════════════════════════════════════════
# COMMANDS
# ════════════════════════════════════════════════════════════════════════════

cmd_setup() {
  echo ""
  echo -e "${WHITE}╔══════════════════════════════════════════╗${NC}"
  echo -e "${WHITE}║        easyBacklog Setup                 ║${NC}"
  echo -e "${WHITE}╚══════════════════════════════════════════╝${NC}"
  echo ""

  check_docker
  ensure_files

  # Offer to generate a secure SECRET_TOKEN
  echo ""
  warn "The default SECRET_TOKEN is a demo value — fine for local use, but should"
  warn "be changed for any shared or internet-facing deployment."
  if prompt_yn "Generate a secure SECRET_TOKEN now?" "Y"; then
    local token
    token=$(openssl rand -hex 64)
    # Replace the SECRET_TOKEN line in .env (works on both Linux and macOS)
    if sed --version &>/dev/null 2>&1; then
      # GNU sed (Linux)
      sed -i "s|^SECRET_TOKEN=.*|SECRET_TOKEN=${token}|" .env
    else
      # BSD sed (macOS) — requires an extension argument
      sed -i '' "s|^SECRET_TOKEN=.*|SECRET_TOKEN=${token}|" .env
    fi
    success "SECRET_TOKEN updated in .env."
  else
    warn "Using demo SECRET_TOKEN. Edit .env to change it later."
  fi

  echo ""
  info "Pulling images..."
  docker compose pull

  echo ""
  info "Starting services..."
  docker compose up -d

  echo ""
  wait_healthy || exit 1

  echo ""
  if db_initialised; then
    info "Database already initialised — skipping."
  else
    init_db
  fi

  echo ""
  echo -e "${WHITE}╔══════════════════════════════════════════╗${NC}"
  echo -e "${WHITE}║        Setup complete!                   ║${NC}"
  echo -e "${WHITE}╠══════════════════════════════════════════╣${NC}"
  printf "${WHITE}║  App URL : %-30s ║${NC}\n" "$APP_URL"
  echo -e "${WHITE}╠══════════════════════════════════════════╣${NC}"
  echo -e "${WHITE}║  Useful commands:                        ║${NC}"
  echo -e "${WHITE}║    ./manage.sh stop                      ║${NC}"
  echo -e "${WHITE}║    ./manage.sh start                     ║${NC}"
  echo -e "${WHITE}║    ./manage.sh status                    ║${NC}"
  echo -e "${WHITE}║    ./manage.sh update                    ║${NC}"
  echo -e "${WHITE}║    ./manage.sh reset                     ║${NC}"
  echo -e "${WHITE}╚══════════════════════════════════════════╝${NC}"
  echo ""
}

cmd_start() {
  check_docker
  ensure_files
  info "Starting services..."
  docker compose up -d
  echo ""
  wait_healthy || true
}

cmd_stop() {
  check_docker
  info "Stopping services (data is kept)..."
  docker compose down
  success "Services stopped."
}

cmd_reset() {
  check_docker
  echo ""
  warn "This will DELETE all data (database, uploads) and reinitialise from scratch."
  if ! confirm "Are you sure you want to reset?"; then
    info "Reset cancelled."
    exit 0
  fi
  info "Stopping and removing volumes..."
  docker compose down -v
  info "Starting services..."
  docker compose up -d
  echo ""
  wait_healthy || exit 1
  echo ""
  init_db
  success "Reset complete."
}

cmd_delete() {
  check_docker
  echo ""
  warn "This will DELETE all containers, volumes, AND the local files (docker-compose.yml, .env)."
  warn "This cannot be undone."
  if ! confirm "Are you sure you want to delete everything?"; then
    info "Delete cancelled."
    exit 0
  fi
  info "Removing containers and volumes..."
  docker compose down -v --remove-orphans
  info "Removing local files..."
  rm -f docker-compose.yml .env
  success "Everything removed."
}

cmd_update() {
  check_docker
  info "Pulling latest images..."
  docker compose pull
  info "Restarting with updated images..."
  docker compose up -d
  echo ""
  wait_healthy || true
  success "Update complete."
}

cmd_status() {
  check_docker
  docker compose ps
}

# ════════════════════════════════════════════════════════════════════════════
# DISPATCH
# ════════════════════════════════════════════════════════════════════════════

COMMAND="${1:-}"

case "$COMMAND" in
  setup)  cmd_setup  ;;
  start)  cmd_start  ;;
  stop)   cmd_stop   ;;
  reset)  cmd_reset  ;;
  delete) cmd_delete ;;
  update) cmd_update ;;
  status) cmd_status ;;
  *)
    echo ""
    echo -e "${WHITE}Usage: ./manage.sh <command>${NC}"
    echo ""
    echo "  setup    First-time setup: download files, start services, init DB"
    echo "  start    Start all services"
    echo "  stop     Stop all services (data is kept)"
    echo "  reset    Wipe all data and reinitialise from scratch"
    echo "  delete   Remove everything (containers, volumes, local files)"
    echo "  update   Pull latest images and restart"
    echo "  status   Show container status"
    echo ""
    exit 1
    ;;
esac
