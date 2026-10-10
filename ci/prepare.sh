#!/bin/sh
# Prepare for the ci card: make Gitea's admin on place forge, before Publish.
# Run it on the forge machine after Start and before Publish, from the directory that holds ci/:
#   sh ci/prepare.sh
set -eu
cd "$(dirname "$0")"
set -a; . ./card.env; set +a
COMPOSE=${COMPOSE:-docker compose --env-file card.env -f docker-compose.yml}

$COMPOSE exec -T -u git gitea \
  gitea admin user create --admin --username gitadmin \
  --password "$GITEA_ADMIN_PASSWORD" --email "$GITEA_ADMIN_EMAIL" --must-change-password=false
