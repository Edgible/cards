#!/usr/bin/env bash
# The grow job's check loop on the hub: check-cards --untrusted --before-test on the agent's
# card, and while it fails, hand the agent the errors to fix, up to ATTEMPTS times. Problems
# the checker can find are fixed here, so the fleet only ever tests a card that passes it.
#
#   .github/scripts/grow-check.sh <card>        prints ready=true or ready=false, and only
#                                                that on stdout: the rest goes to stderr
set -euo pipefail
card=$1
here=$(dirname "$0")
for attempt in $(seq 1 "${ATTEMPTS:-3}"); do
  if (cd work/cards && ../card-kit/run check-cards --untrusted --before-test "$card/card.yml") > check.log 2>&1; then
    echo "check passed (attempt $attempt)" >&2; echo "ready=true"; exit 0
  fi
  cat check.log >&2
  [ "$attempt" -lt "${ATTEMPTS:-3}" ] || break
  "$here/grow-agent.sh" "The $card card you made does not pass check-cards. Fix the card, change nothing outside $card/, check it again with ../card-kit/run check-cards --untrusted --before-test $card/card.yml, and update NEW-CARD.md if the auth modes or app changed. What it said: $(cat check.log)" >&2
done
echo "ready=false"
