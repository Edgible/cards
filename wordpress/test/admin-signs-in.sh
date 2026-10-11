# A check for test-card, run after Verify with card.env exported and HOSTNAME_<APP> set.
# The admin prepare.sh made signs in over the public hostname, and is sent on to the dashboard.
set -eu
B="https://$HOSTNAME_WORDPRESS"
curl -fsS -o /dev/null -D - -b 'wordpress_test_cookie=WP%20Cookie%20check' \
  --data-urlencode log=admin --data-urlencode "pwd=$WORDPRESS_ADMIN_PASSWORD" -d testcookie=1 \
  "$B/wp-login.php" | grep -qi '^location: .*/wp-admin/'
