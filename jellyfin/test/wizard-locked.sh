# A check for test-card, run after Verify with card.env exported and HOSTNAME_<APP> set.
# The setup wizard refuses a new admin, and the admin prepare.sh made signs in.
set -eu
B="https://$HOSTNAME_JELLYFIN"; H='Content-Type: application/json'
code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$B/Startup/User" -H "$H" -d '{"Name":"x","Password":"x"}')
[ "$code" = 401 ] || { echo "the wizard answered $code"; exit 1; }
curl -fsS -X POST "$B/Users/AuthenticateByName" -H "$H" \
  -H 'Authorization: MediaBrowser Client="test-card", Device="test-card", DeviceId="test-card", Version="1"' \
  -d "{\"Username\":\"$JELLYFIN_ADMIN_USER\",\"Pw\":\"$JELLYFIN_ADMIN_PASSWORD\"}" | grep -q AccessToken
