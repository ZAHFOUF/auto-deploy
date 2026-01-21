#!/usr/bin/env bash
set -e
whoami
# Chemin ABSOLU vers le fichier de config
CONFIG_FILE="/deploy/apps.config"

if [ ! -f "$CONFIG_FILE" ]; then
  echo " Config file not found: $CONFIG_FILE"
  exit 1
fi

# Importer la config
source "$CONFIG_FILE"

if [ -z "${APPS[*]}" ]; then
  echo " No applications defined in config"
  exit 1
fi

if [ -z "$BRANCH" ]; then
  echo " BRANCH is not defined in config"
  exit 1
fi

echo " Starting deploy on branch: $BRANCH"
echo " Apps loaded from: $CONFIG_FILE"

for DIR in "${APPS[@]}"; do
  echo "=============================="
  echo " Deploying: $DIR"

  if [ ! -d "$DIR/.git" ]; then
    echo " Not a git repository: $DIR"
    exit 1
  fi

  cd "$DIR"

  echo " git pull origin $BRANCH"
  git pull origin "$BRANCH" --force

  CACHE_DIR="$DIR/var/cache/prod"
  if [ -d "$CACHE_DIR" ]; then
    echo " Clearing cache: $CACHE_DIR"
    rm -rf "$CACHE_DIR"
  else
    echo " Cache directory not found: $CACHE_DIR"
  fi

  echo "Done: $DIR"

  CACHE_DIR="$DIR/var/cache/bash"
  if [ -d "$CACHE_DIR" ]; then
    echo "Clearing cache BASH: $CACHE_DIR"
    rm -rf "$CACHE_DIR"
  else
    echo "Cache directory not found: $CACHE_DIR"
  fi

  echo "Done bash : $DIR"

  echo "Starting migration: $DIR"
  php $DIR/bin/console doctrine:migrations:migrate --no-interaction
  echo "Done migration: $DIR"


done

echo "­All apps deployed successfully"
