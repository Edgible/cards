#!/bin/sh
# Apply the assistant card's changes to the Open WebUI gold Compose file.
# The file must already be the gold file that project publishes.
# Usage: tailor.sh DIR
# DIR holds docker-compose.yaml and card.env. The ports come from card.env.
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

dir=${1:?pass the directory that holds docker-compose.yaml and card.env}
compose="$dir/docker-compose.yaml"
envfile="$dir/card.env"

test -f "$compose"
test -f "$envfile"
set -a
. "$envfile"
set +a

case ${ASSISTANT_PORT-} in
  ''|*[!0-9]*)
    echo "tailor.sh: ASSISTANT_PORT must be a port number in $envfile" >&2
    exit 1
    ;;
esac
case ${OLLAMA_PORT-} in
  ''|*[!0-9]*)
    echo "tailor.sh: OLLAMA_PORT must be a port number in $envfile" >&2
    exit 1
    ;;
esac

chat_bind="127.0.0.1:${ASSISTANT_PORT}:8080"
ollama_bind="127.0.0.1:${OLLAMA_PORT}:11434"

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
  sed -i "s/- \${OPEN_WEBUI_PORT-3000}:8080/- ${chat_bind}/" "$compose"
fi
require "$compose" "- ${chat_bind}"
absent "$compose" 'OPEN_WEBUI_PORT'

if ! grep -q "$ollama_bind" "$compose"; then
  absent "$compose" '11434:11434'
  sed -i "/image: ollama\\/ollama:/a\\
    ports:\\
      - ${ollama_bind}" "$compose"
fi
require "$compose" "- ${ollama_bind}"
require "$compose" 'OLLAMA_BASE_URL=http://ollama:11434'

if [ "$(grep -c "$chat_bind" "$compose")" -ne 1 ]; then
  echo "tailor.sh: expected one chat port in $compose" >&2
  exit 1
fi
if [ "$(grep -c "${OLLAMA_PORT}:11434" "$compose")" -ne 1 ]; then
  echo "tailor.sh: expected one Ollama port in $compose" >&2
  exit 1
fi
