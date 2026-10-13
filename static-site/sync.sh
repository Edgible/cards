#!/bin/sh
# Keep the static-site card's files in step with STATIC_SITE_SOURCE.
#
# Every STATIC_SITE_EVERY seconds it asks the source for the site's .tar.gz. A new version
# goes live only when it downloaded in full, changed, has no paths that reach outside its
# folder, and has an index.html at its top. Anything else leaves the live site as it is.
# Going live is one rename of the current link, so a visitor never sees half a site.
#
#   current -> releases/<hash>   the live version, which Caddy serves
#   releases/                    the live version and the one before it
set -eu

W=/home/curl_user
SOURCE=$STATIC_SITE_SOURCE
STRIP=${STATIC_SITE_STRIP:-1}
EVERY=${STATIC_SITE_EVERY:-300}
MAX=200M

cd "$W"
mkdir -p releases

log() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $*"; }

update() {
  tmp=$(mktemp -d "$W/.incoming.XXXXXX")
  # The ETag asks the source to send nothing when nothing changed.
  code=$(curl -sSL --max-filesize "$MAX" --connect-timeout 20 --max-time 300 \
           --etag-compare .etag --etag-save "$tmp/etag" \
           -o "$tmp/site.tar.gz" -w '%{http_code}' "$SOURCE") || code=failed
  case "$code" in
    304) rm -rf "$tmp"; return 0 ;;
    200) ;;
    *) log "download failed ($code): the live site stays as it is"; rm -rf "$tmp"; return 0 ;;
  esac

  hash=$(sha256sum "$tmp/site.tar.gz" | cut -c1-16)
  if [ -e "releases/$hash" ] && [ "$(readlink current 2>/dev/null)" = "releases/$hash" ]; then
    mv -f "$tmp/etag" .etag; rm -rf "$tmp"; return 0
  fi

  if ! tar -tzf "$tmp/site.tar.gz" > "$tmp/list" 2> "$tmp/warnings"; then
    log "not a readable .tar.gz: the live site stays as it is"; rm -rf "$tmp"; return 0
  fi
  # A path that starts with / or holds .. could write outside the site's folder. tar
  # cleans such names as it lists them, and says so, so both its listing and its
  # warnings are checked.
  if grep -qE '(^/|(^|/)\.\.(/|$))' "$tmp/list" || grep -q 'removing leading' "$tmp/warnings"; then
    log "the archive has paths outside its folder: refused, the live site stays as it is"
    rm -rf "$tmp"; return 0
  fi

  mkdir "$tmp/site"
  tar -xzf "$tmp/site.tar.gz" -C "$tmp/site" --strip-components "$STRIP"
  if [ ! -f "$tmp/site/index.html" ]; then
    log "no index.html at the top (check STATIC_SITE_STRIP): the live site stays as it is"
    rm -rf "$tmp"; return 0
  fi

  rm -rf "releases/$hash"
  mv "$tmp/site" "releases/$hash"
  ln -sfn "releases/$hash" "$tmp/current"
  mv -fT "$tmp/current" current
  mv -f "$tmp/etag" .etag
  rm -rf "$tmp"
  log "live: $hash"

  # Keep the live version and the one before it.
  ls -1t releases | tail -n +3 | while read -r old; do rm -rf "releases/$old"; done
}

log "source: $SOURCE, every ${EVERY}s"
while true; do
  rm -rf .incoming.*
  update || log "update failed: the live site stays as it is"
  sleep "$EVERY"
done
