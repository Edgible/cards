# A check for test-card, run after the runner has started, with card.env exported and HOSTNAME_<APP> set.
# The same check a person runs in Verify, from etc/verify-ci.sh.
set -eu
sh "$(dirname "$0")/../etc/verify-ci.sh" workflow
