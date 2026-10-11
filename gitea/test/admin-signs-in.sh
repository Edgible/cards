# A check for test-card, run after Verify with card.env exported and HOSTNAME_<APP> set.
# The admin prepare.sh made signs in to the API over the public hostname.
set -eu
curl -fsS -u "gitadmin:$GITEA_ADMIN_PASSWORD" "https://$HOSTNAME_GITEA/api/v1/user" | grep -q '"is_admin":true'
