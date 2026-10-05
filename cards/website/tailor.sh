#!/bin/sh
# Apply the website card's changes to the Umami and Uptime Kuma Compose files.
# The files must already be the gold files those projects publish.
# Usage: tailor.sh [umami_dir] [uptime_kuma_dir]
# Defaults: ~/umami and ~/uptime-kuma
set -eu

require() {
  if ! grep -F -q -- "$2" "$1"; then
    echo "tailor.sh: missing '$2' in $1" >&2
    exit 1
  fi
}

absent() {
  if grep -F -q -- "$2" "$1"; then
    echo "tailor.sh: still found '$2' in $1" >&2
    exit 1
  fi
}

umami=${1:-$HOME/umami}
kuma=${2:-$HOME/uptime-kuma}

test -f "$umami/docker-compose.yml"
test -f "$kuma/compose.yaml"

sed -i \
  -e 's/"3000:3000"/"127.0.0.1:3000:3000"/' \
  -e 's#postgresql://umami:umami@#postgresql://umami:${POSTGRES_PASSWORD}@#' \
  -e 's/APP_SECRET: replace-me-with-a-random-string/APP_SECRET: ${APP_SECRET}/' \
  -e 's/TWO_FACTOR_ENCRYPTION_KEY: replace-me-with-a-64-character-hex-string/TWO_FACTOR_ENCRYPTION_KEY: ${TWO_FACTOR_ENCRYPTION_KEY}/' \
  -e 's/POSTGRES_PASSWORD: umami/POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}/' \
  "$umami/docker-compose.yml"

sed -i 's/"3001:3001"/"127.0.0.1:3001:3001"/' "$kuma/compose.yaml"

require "$umami/docker-compose.yml" '"127.0.0.1:3000:3000"'
require "$umami/docker-compose.yml" 'postgresql://umami:${POSTGRES_PASSWORD}@'
require "$umami/docker-compose.yml" 'APP_SECRET: ${APP_SECRET}'
require "$umami/docker-compose.yml" 'TWO_FACTOR_ENCRYPTION_KEY: ${TWO_FACTOR_ENCRYPTION_KEY}'
require "$umami/docker-compose.yml" 'POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}'
absent "$umami/docker-compose.yml" '"3000:3000"'
absent "$umami/docker-compose.yml" 'postgresql://umami:umami@'
absent "$umami/docker-compose.yml" 'replace-me'
absent "$umami/docker-compose.yml" 'POSTGRES_PASSWORD: umami'
require "$kuma/compose.yaml" '"127.0.0.1:3001:3001"'
absent "$kuma/compose.yaml" '"3001:3001"'

if [ ! -f "$umami/.env" ]; then
  cat > "$umami/.env" <<EOF
POSTGRES_PASSWORD=$(openssl rand -hex 16)
APP_SECRET=$(openssl rand -base64 32)
TWO_FACTOR_ENCRYPTION_KEY=$(openssl rand -hex 32)
EOF
  chmod 600 "$umami/.env"
elif ! grep -q '^TWO_FACTOR_ENCRYPTION_KEY=' "$umami/.env"; then
  echo "TWO_FACTOR_ENCRYPTION_KEY=$(openssl rand -hex 32)" >> "$umami/.env"
fi
