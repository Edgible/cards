# A check for test-card, run after Verify with card.env exported and HOSTNAME_<APP> set.
# The open hostname answers with the canary itself, and the request reached it through a
# proxy: Edgible adds X-Forwarded headers on the way, so a reply without them came some
# other way.
set -eu
body=$(curl -fsS "https://$HOSTNAME_CANARY/")
echo "$body" | grep -q '^Name: canary' || { echo "the answer is not the canary's: $(echo "$body" | head -1)"; exit 1; }
echo "$body" | grep -qi '^X-Forwarded-' || { echo "no X-Forwarded headers, so the request did not come through Edgible"; exit 1; }
