# A check for test-card, run after Verify with card.env exported and HOSTNAME_<APP> set.
# The admin prepare.sh made signs in over the public hostname.
set -eu
curl -fsS -X POST "https://$HOSTNAME_IMMICH/api/auth/login" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$IMMICH_ADMIN_EMAIL\",\"password\":\"$IMMICH_ADMIN_PASSWORD\"}" | grep -q accessToken
