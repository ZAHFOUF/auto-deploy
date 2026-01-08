#!/usr/bin/env bash
set -e
whoami
# Chemin ABSOLU vers le fichier de config
CONFIG_FILE="/deploy/apps.config"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "ÔØî Config file not found: $CONFIG_FILE"
  exit 1
fi

# Importer la config
source "$CONFIG_FILE"

if [ -z "${APPS[*]}" ]; then
  echo "ÔØî No applications defined in config"
  exit 1
fi

if [ -z "$BRANCH" ]; then
  echo "ÔØî BRANCH is not defined in config"
  exit 1
fi

echo "­ƒÜÇ Starting deploy on branch: $BRANCH"
echo "­ƒôü Apps loaded from: $CONFIG_FILE"

for DIR in "${APPS[@]}"; do
  echo "=============================="
  echo "­ƒôª Deploying: $DIR"

  if [ ! -d "$DIR/.git" ]; then
    echo "ÔØî Not a git repository: $DIR"
    exit 1
  fi

  cd "$DIR"

  echo "­ƒöä git pull origin $BRANCH"
  git pull origin "$BRANCH"

  CACHE_DIR="$DIR/var/cache/prod"
  if [ -d "$CACHE_DIR" ]; then
    echo "­ƒº╣ Clearing cache: $CACHE_DIR"
    rm -rf "$CACHE_DIR"
  else
    echo "Ôä╣´©Å Cache directory not found: $CACHE_DIR"
  fi

  echo "Ô£à Done: $DIR"

  CACHE_DIR="$DIR/var/cache/bash"
  if [ -d "$CACHE_DIR" ]; then
    echo "­ƒº╣ Clearing cache BASH: $CACHE_DIR"
    rm -rf "$CACHE_DIR"
  else
    echo "Ôä╣´©Å Cache directory not found: $CACHE_DIR"
  fi

  echo "Ô£à Done bash : $DIR"


done

echo "­ƒÄë All apps deployed successfully"
