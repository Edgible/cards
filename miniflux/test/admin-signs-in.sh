# A check for test-card, run after Verify with card.env exported and HOSTNAME_<APP> set.
# miniflux is on org, so this asks the app on the machine: the admin made from card.env
# signs in to the API, and a wrong password is refused.
set -eu
B="http://127.0.0.1:$MINIFLUX_PORT"
code=$(curl -s -o /dev/null -w '%{http_code}' -u "admin:wrong-$MINIFLUX_ADMIN_PASSWORD" "$B/v1/me")
[ "$code" = 401 ] || { echo "a wrong password answered $code"; exit 1; }
curl -fsS -u "admin:$MINIFLUX_ADMIN_PASSWORD" "$B/v1/me" | grep -q '"is_admin":true'
