#!/bin/sh
# Apply the assistant card's changes to the Open WebUI gold Compose file.
# The file must already be the gold file that project publishes.
# Usage: tailor.sh DIR
# DIR holds docker-compose.yaml.
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

dir=${1:?pass the directory that holds docker-compose.yaml}
compose="$dir/docker-compose.yaml"

test -f "$compose"

require "$compose" 'image: ollama/ollama:${OLLAMA_DOCKER_TAG-latest}'
require "$compose" 'image: ghcr.io/open-webui/open-webui:${WEBUI_DOCKER_TAG-main}'
require "$compose" 'OLLAMA_BASE_URL=http://ollama:11434'

if grep -q '^    build:$' "$compose"; then
  sed -i "/^    build:\$/,/^    image: ghcr.io\\/open-webui\\/open-webui:/ {
    /^    image: ghcr.io\\/open-webui\\/open-webui:/!d
  }" "$compose"
fi
absent "$compose" '    build:'
absent "$compose" 'dockerfile: Dockerfile'

if grep -q '${OPEN_WEBUI_PORT-3000}:8080' "$compose"; then
  sed -i 's/- ${OPEN_WEBUI_PORT-3000}:8080/- 127.0.0.1:8088:8080/' "$compose"
fi
require "$compose" '- 127.0.0.1:8088:8080'
absent "$compose" 'OPEN_WEBUI_PORT'

if ! grep -q '127.0.0.1:11434:11434' "$compose"; then
  absent "$compose" '11434:11434'
  sed -i "/image: ollama\\/ollama:/a\\
    ports:\\
      - 127.0.0.1:11434:11434" "$compose"
fi
require "$compose" '- 127.0.0.1:11434:11434'
require "$compose" 'OLLAMA_BASE_URL=http://ollama:11434'

if [ "$(grep -c '127.0.0.1:8088:8080' "$compose")" -ne 1 ]; then
  echo "tailor.sh: expected one chat port in $compose" >&2
  exit 1
fi
if [ "$(grep -c '11434:11434' "$compose")" -ne 1 ]; then
  echo "tailor.sh: expected one Ollama port in $compose" >&2
  exit 1
fi
