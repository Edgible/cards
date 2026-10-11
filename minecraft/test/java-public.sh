# A check for test-card, run after Verify with card.env exported and HOSTNAME_<APP> set.
# Java Edition's status answers over TCP through the gateway.
set -eu
python3 "$(dirname "$0")/mcping.py" java "$HOSTNAME_MC_JAVA" "$MC_JAVA_PORT"
