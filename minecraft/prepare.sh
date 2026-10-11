#!/bin/sh
# Prepare for the minecraft card: switch Geyser to Floodgate sign-in, so Bedrock players sign in with Xbox.
# Run it after Start and before Publish, from the directory that holds minecraft/:
#   sh minecraft/prepare.sh
set -eu
cd "$(dirname "$0")"
set -a; . ./card.env; set +a
COMPOSE=${COMPOSE:-docker compose --env-file card.env -f docker-compose.yml}

$COMPOSE exec -T minecraft \
  sed -i 's/auth-type: online/auth-type: floodgate/' /data/plugins/Geyser-Spigot/config.yml
$COMPOSE restart minecraft
$COMPOSE up -d --wait
