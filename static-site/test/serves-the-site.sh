# A check for test-card, run after Verify with card.env exported and HOSTNAME_<APP> set.
# The public hostname serves the source's own index.html, byte for byte, and a page the
# site does not have answers 404.
set -eu
B="https://$HOSTNAME_STATIC_SITE"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
curl -fsSL "$STATIC_SITE_SOURCE" | tar -xzf - -C "$t" --strip-components "$STATIC_SITE_STRIP"
curl -fsS "$B/" -o "$t/served.html"
cmp -s "$t/index.html" "$t/served.html" || { echo "the site's front page is not the source's index.html"; exit 1; }
code=$(curl -s -o /dev/null -w '%{http_code}' "$B/no-such-page-$$")
[ "$code" = 404 ] || { echo "a page the site does not have answered $code, not 404"; exit 1; }
