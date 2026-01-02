#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[start-dev] $*"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DB_DIR="$ROOT_DIR/db"
COMPOSE_FILE="$DB_DIR/docker-compose.yml"
ENV_FILE="$DB_DIR/.env"
SERVICE_NAME="postgres"

POSTGRES_USER="cc_user"
POSTGRES_DB="witcher_cc"

trim() {
  local var="$1"
  var="${var#"${var%%[![:space:]]*}"}"
  var="${var%"${var##*[![:space:]]}"}"
  printf '%s' "$var"
}

if [[ -f "$ENV_FILE" ]]; then
  while IFS='=' read -r key value || [[ -n "$key" ]]; do
    key="$(trim "${key%$'\r'}")"
    [[ -z "$key" || "$key" == \#* ]] && continue
    value="$(trim "${value%$'\r'}")"
    value="${value%\"}"
    value="${value#\"}"
    case "$key" in
      POSTGRES_USER) POSTGRES_USER="$value" ;;
      POSTGRES_DB) POSTGRES_DB="$value" ;;
    esac
  done < "$ENV_FILE"
fi

declare -a COMPOSE_BIN
if docker compose version >/dev/null 2>&1; then
  COMPOSE_BIN=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_BIN=(docker-compose)
else
  log "docker compose is not installed. Please install it first."
  exit 1
fi

is_db_running() {
  "${COMPOSE_BIN[@]}" -f "$COMPOSE_FILE" ps --status running "$SERVICE_NAME" >/dev/null 2>&1
}

ensure_db() {
  if is_db_running; then
    log "database container is already running."
  else
    log "starting database container..."
    "${COMPOSE_BIN[@]}" -f "$COMPOSE_FILE" up -d "$SERVICE_NAME"
  fi
}

wait_for_db() {
  log "waiting for database to become ready..."
  for ((i = 1; i <= 30; i++)); do
    if "${COMPOSE_BIN[@]}" -f "$COMPOSE_FILE" exec -T "$SERVICE_NAME" pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
      log "database is ready."
      return
    fi
    sleep 1
  done
  log "database failed to become ready within 30 seconds." >&2
  exit 1
}

seed_db() {
  log "running db/seed.sh..."
  (cd "$DB_DIR" && ./seed.sh)
}

ensure_dependencies() {
  log "checking dependencies..."
  if [ ! -d "$ROOT_DIR/node_modules" ]; then
    log "node_modules not found. Installing dependencies..."
    cd "$ROOT_DIR"
    npm install || {
      log "failed to install dependencies"
      exit 1
    }
  elif [ ! -f "$ROOT_DIR/node_modules/.bin/tsx" ] && [ ! -f "$ROOT_DIR/node_modules/.bin/next" ]; then
    log "dependencies incomplete. Installing..."
    cd "$ROOT_DIR"
    npm install || {
      log "failed to install dependencies"
      exit 1
    }
  fi
  log "dependencies are ready."
}

stop_dev_servers() {
  log "stopping existing dev servers (if any)..."
  pkill -f "npm --workspace apps/api run dev" >/dev/null 2>&1 || true
  pkill -f "npm --workspace apps/web run dev" >/dev/null 2>&1 || true
  pkill -f "npm run dev" >/dev/null 2>&1 || true
  pkill -f "tsx watch src/server.ts" >/dev/null 2>&1 || true
  pkill -f "next dev" >/dev/null 2>&1 || true
}

ensure_db
wait_for_db
seed_db
ensure_dependencies
stop_dev_servers

log "starting web and api dev servers..."
cd "$ROOT_DIR"
npm run dev

