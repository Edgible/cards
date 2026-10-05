#!/bin/sh
# Apply the n8n card's changes to the gold Compose file and its .env.
# Usage: tailor.sh DIR ORG
# DIR holds docker-compose.yml and .env. ORG is the org label, not a hostname.
set -eu

dir=${1:?pass the directory that holds docker-compose.yml}
org=${2:?pass the org label}

case $org in
  *[!a-z0-9-]*)
    echo "org label must be letters, digits, and hyphens" >&2
    exit 1
    ;;
esac

test -f "$dir/docker-compose.yml"
test -f "$dir/.env"

sed -i 's/- 5678:5678/- 127.0.0.1:5678:5678/' "$dir/docker-compose.yml"

if grep -qE 'changePassword|changeRunnerAuthToken' "$dir/.env"; then
  postgres_password=$(openssl rand -hex 16)
  postgres_non_root_password=$(openssl rand -hex 16)
  runners_auth_token=$(openssl rand -hex 32)
  sed -i \
    -e "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=${postgres_password}/" \
    -e "s/^POSTGRES_NON_ROOT_PASSWORD=.*/POSTGRES_NON_ROOT_PASSWORD=${postgres_non_root_password}/" \
    -e "s/^RUNNERS_AUTH_TOKEN=.*/RUNNERS_AUTH_TOKEN=${runners_auth_token}/" \
    "$dir/.env"
  chmod 600 "$dir/.env"
fi

if ! grep -q '^      - WEBHOOK_URL=' "$dir/docker-compose.yml"; then
  sed -i "/N8N_RUNNERS_BROKER_LISTEN_ADDRESS=0.0.0.0/a\\
      - N8N_PROXY_HOPS=1\\
      - N8N_PROTOCOL=https\\
      - N8N_HOST=n8n.${org}.edgible.com\\
      - N8N_EDITOR_BASE_URL=https://n8n.${org}.edgible.com/\\
      - WEBHOOK_URL=https://n8n-hooks.${org}.edgible.com/" "$dir/docker-compose.yml"
fi
