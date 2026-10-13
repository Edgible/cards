#!/usr/bin/env bash
# Join a Linux machine (or WSL2 Ubuntu) to the cards' test fleet: Docker, the tools test-card
# uses, and a GitHub Actions runner for edgible-org/cards that tests on this machine's own
# Edgible device. Run it as your normal user, not root, on a machine whose Edgible agent is
# already a serving device in the test organization and whose `edgible` CLI is signed in.
#
#   curl -fsSL https://raw.githubusercontent.com/edgible-org/cards/main/.github/scripts/join-fleet.sh \
#     | bash -s -- <registration-token> <edgible-device-name> <labels>
#
# The registration token comes from a maintainer and lasts an hour. Labels describe the
# machine, such as fleet-vbox; the script adds a mem-<n>g label for each memory tier the
# machine meets (mem-2g,mem-4g,mem-8g on a 9 GB one), which the regression matches against
# each card's places:. Add edgible-test to take tonight's tests; leave it out to try the
# machine first with runner-check. No Claude token: fleet machines only test. Nothing here
# opens an inbound port.
set -euo pipefail
token=${1:?registration token}
device=${2:?Edgible device name, as edgible device list prints it}
labels=${3:?labels, such as fleet-vbox or fleet-vbox,edgible-test}
# The memory tiers, as card-kit's test-cards.py names them; a little under the tier still
# counts, since the kernel keeps some memory for itself.
mem=$(awk '/^MemTotal:/ {print $2 * 1024}' /proc/meminfo)
for t in 2 4 8 16 32 64; do
  awk -v m="$mem" -v t="$t" 'BEGIN {exit !(m >= t * 0.9e9)}' && labels="$labels,mem-${t}g"
done
[ "$(id -u)" != 0 ] || { echo "run it as your normal user, not root" >&2; exit 2; }

# A runner service needs systemd. On WSL2: add [boot] systemd=true to /etc/wsl.conf, run
# `wsl --shutdown` from Windows, and open WSL again.
[ "$(ps -p 1 -o comm=)" = systemd ] || { echo "systemd is not running as PID 1 (on WSL2, see the comment above)" >&2; exit 2; }
if grep -qi microsoft /proc/version; then
  echo "WSL2: keep the VM up at night with vmIdleTimeout=-1 under [wsl2] in %UserProfile%\\.wslconfig, and stop Windows sleeping on power"
fi

echo "== Docker and tools"
sudo apt-get update -qq
sudo apt-get install -y -qq python3 curl jq dnsutils git
# A machine that already has Docker, such as Docker's own docker-ce packages, keeps it:
# Ubuntu's docker.io would clash with them.
if command -v docker >/dev/null && docker compose version >/dev/null 2>&1; then
  echo "Docker is already installed: $(docker --version)"
else
  sudo apt-get install -y -qq docker.io docker-compose-v2
fi
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

echo "== Edgible"
command -v edgible >/dev/null || { echo "install the Edgible CLI and agent first, and sign in" >&2; exit 2; }
edgible device list --json | python3 -c "
import json, sys
name = sys.argv[1]
mine = [d for d in json.load(sys.stdin) if d.get('name') == name]
sys.exit(f'need exactly one device named {name}, found {len(mine)}') if len(mine) != 1 else print(f'{name}:', mine[0].get('status'))
" "$device"

echo "== GitHub runner"
mkdir -p ~/actions-runner && cd ~/actions-runner
if [ ! -f .runner ]; then
  arch=$(dpkg --print-architecture); [ "$arch" = amd64 ] && arch=x64
  v=$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | sed 's/^v//')
  curl -fsSLo runner.tgz "https://github.com/actions/runner/releases/download/v$v/actions-runner-linux-$arch-$v.tar.gz"
  tar xzf runner.tgz && rm runner.tgz
  sudo ./bin/installdependencies.sh >/dev/null
  ./config.sh --url https://github.com/edgible-org/cards --token "$token" \
    --name "$device" --labels "$labels" --unattended
fi
grep -q '^TEST_DEVICE=' .env 2>/dev/null || printf 'LANG=C.UTF-8\nTEST_DEVICE=%s\n' "$device" >> .env
# The service starts with the docker group, which this login session may not have yet.
sudo ./svc.sh install "$USER" >/dev/null 2>&1 || true
sudo ./svc.sh stop >/dev/null 2>&1 || true
sudo ./svc.sh start
sudo ./svc.sh status | head -3
echo "== Done. A maintainer can now run runner-check with one of these labels: $labels"
