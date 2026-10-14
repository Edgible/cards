#!/bin/sh
# Stop the service and remove what install.sh installed: the service file and the release.
# The models stay: in this card's directory they go when you remove the card, and anywhere
# else (OLLAMA_MODELS) they are not this card's to delete. Run it with card.env exported:
#
#   set -a; . ollama-mac/card.env; set +a
#   sh ollama-mac/uninstall.sh
set -eu

: "${SERVICE:?set SERVICE in card.env}"
dir=$(cd "$(dirname "$0")" && pwd)
plist="$HOME/Library/LaunchAgents/$SERVICE.plist"

launchctl bootout "gui/$(id -u)/$SERVICE" 2>/dev/null || true
rm -f "$plist"
rm -rf "$dir/.native"
echo "removed the $SERVICE service and Ollama; the models are where they were"
