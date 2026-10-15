# A check for test-card, run after Verify with card.env exported and HOSTNAME_<APP> set.
# The public hostname serves the source's own index.html, byte for byte. A page the site
# does not have answers 404, or, with STATIC_SITE_FALLBACK set, that page with 200.
set -eu
B="https://$HOSTNAME_STATIC_SITE"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
curl -fsSL "$STATIC_SITE_SOURCE" | tar -xzf - -C "$t" --strip-components "$STATIC_SITE_STRIP"
curl -fsS "$B/" -o "$t/served.html"
cmp -s "$t/index.html" "$t/served.html" || { echo "the site's front page is not the source's index.html"; exit 1; }
code=$(curl -s -o "$t/missing.html" -w '%{http_code}' "$B/no-such-page-$$")
if [ -n "${STATIC_SITE_FALLBACK:-}" ]; then
  [ "$code" = 200 ] || { echo "a page the site does not have answered $code, not 200 with $STATIC_SITE_FALLBACK"; exit 1; }
  cmp -s "$t$STATIC_SITE_FALLBACK" "$t/missing.html" || { echo "a page the site does not have was not $STATIC_SITE_FALLBACK"; exit 1; }
else
  [ "$code" = 404 ] || { echo "a page the site does not have answered $code, not 404"; exit 1; }
fi
