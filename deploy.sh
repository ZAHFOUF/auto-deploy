#!/usr/bin/env bash
set -euo pipefail

# =========================
# Config
# =========================
CONFIG_FILE="apps.config"

# =========================
# Helpers
# =========================
log() { echo -e "✅ $*"; }
warn() { echo -e "⚠️ $*"; }
err() { echo -e "❌ $*" >&2; }

usage() {
  cat <<EOF
Usage:
  deploy.sh                # Déploie toutes les apps définies dans APPS[] avec BRANCH
  deploy.sh --project AFEC # Déploie une seule app via variable AFEC_DIR (sans branch)
Options:
  -p, --project   Nom du projet (ex: AFEC, OSENGO, BLUME)
  -c, --config    Chemin du fichier config (défaut: /deploy/apps.config)
  -h, --help      Afficher l'aide
EOF
}

# =========================
# Parse args
# =========================
PROJECT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--project)
      PROJECT="${2:-}"
      shift 2
      ;;
    -c|--config)
      CONFIG_FILE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage; exit 0
      ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# =========================
# Load config
# =========================
whoami

if [[ ! -f "$CONFIG_FILE" ]]; then
  err "Config file not found: $CONFIG_FILE"
  exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

# =========================
# Functions
# =========================
clear_cache_dirs() {
  local dir="$1"

  local cache_prod="$dir/var/cache/prod"
  if [[ -d "$cache_prod" ]]; then
    log "Clearing cache: $cache_prod"
    rm -rf "$cache_prod"
  else
    warn "Cache directory not found: $cache_prod"
  fi

  local cache_bash="$dir/var/cache/bash"
  if [[ -d "$cache_bash" ]]; then
    log "Clearing cache BASH: $cache_bash"
    rm -rf "$cache_bash"
  else
    warn "Cache directory not found: $cache_bash"
  fi
}

run_migrations() {
  local dir="$1"
  log "Starting migration: $dir"
  php "$dir/bin/console" doctrine:migrations:migrate --no-interaction --env=bash
  log "Done migration: $dir"
}

run_permissions() {
  local dir="$1"
  log "Starting permissions: $dir"
  php "$dir/bin/console" load:permissions --env=bash
  log "Done permissions: $dir"
}

run_tests () {
  local dir="$1"
  log "Running healthcheck for: $dir"
  php "$dir/bin/console" app:deploy:healthcheck --env=bash
  log "Healthcheck passed for: $dir"
}

deploy_dir_with_branch() {
  local dir="$1"
  local branch="$2"

  echo "=============================="
  log "Deploying: $dir"

  if [[ ! -d "$dir/.git" ]]; then
    err "Not a git repository: $dir"
    exit 1
  fi

  pushd "$dir" >/dev/null

  log "git pull origin $branch" --force
  git pull origin "$branch" --force

  popd >/dev/null

  clear_cache_dirs "$dir"
  run_migrations "$dir"
  run_tests "$dir"

  log "Done: $dir"
}

deploy_dir_no_branch() {
  local dir="$1"

  echo "=============================="
  log "Deploying (no-branch mode): $dir"

  if [[ ! -d "$dir/.git" ]]; then
    err "Not a git repository: $dir"
    exit 1
  fi

  pushd "$dir" >/dev/null

  log "git pull (current branch)"
  git pull --force

  popd >/dev/null

  clear_cache_dirs "$dir"
  run_migrations "$dir"
  run_tests "$dir"

  log "Done: $dir"
}



# =========================
# Main logic
# =========================

# Case 1: --project provided => deploy only that project without branch
if [[ -n "$PROJECT" ]]; then
  # Ex: PROJECT=AFEC => var name AFEC_DIR
  VAR_NAME="${PROJECT}_DIR"

  # indirect expansion to read a var by name
  PROJECT_DIR="${!VAR_NAME:-}"

  if [[ -z "$PROJECT_DIR" ]]; then
    err "Project dir not defined in config: $VAR_NAME"
    err "Example in config: ${VAR_NAME}=\"/var/www/${PROJECT,,}\""
    exit 1
  fi

  log "Project mode: $PROJECT -> $PROJECT_DIR"
  deploy_dir_no_branch "$PROJECT_DIR"
  log "All good."
  exit 0
fi

# Case 2: default => deploy all apps with BRANCH
if [[ -z "${APPS[*]-}" ]]; then
  err "No applications defined in config (APPS array)"
  exit 1
fi

if [[ -z "${BRANCH:-}" ]]; then
  err "BRANCH is not defined in config"
  exit 1
fi

log "Starting deploy on branch: $BRANCH"
log "Apps loaded from: $CONFIG_FILE"

for dir in "${APPS[@]}"; do
  deploy_dir_with_branch "$dir" "$BRANCH"
done

log "All apps deployed successfully"
