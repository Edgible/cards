# A check for test-card, run after Verify with card.env exported and HOSTNAME_<APP> set.
# Geyser answers a Bedrock ping over UDP through the gateway.
set -eu
python3 "$(dirname "$0")/mcping.py" bedrock "$HOSTNAME_MC_BEDROCK" "$MC_BEDROCK_PORT"
