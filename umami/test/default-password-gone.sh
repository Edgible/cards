# A check for test-card, run after Verify with card.env exported and HOSTNAME_<APP> set.
# The default password is refused, and the one prepare.sh set signs in. analytics is on none.
set -eu
B="https://$HOSTNAME_ANALYTICS"; H='Content-Type: application/json'
code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$B/api/auth/login" -H "$H" -d '{"username":"admin","password":"umami"}')
[ "$code" = 401 ] || { echo "the default password answered $code"; exit 1; }
curl -fsS -X POST "$B/api/auth/login" -H "$H" \
  -d "{\"username\":\"admin\",\"password\":\"$UMAMI_ADMIN_PASSWORD\"}" | grep -q token
