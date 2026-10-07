# website

## Why

A site, the count of who read it, and a check that it is still up are usually three services someone else runs. This card keeps all three on machines you own. Strangers can open the site and the tracking script. The dashboard and the monitor ask for an org login.

## What

`site` is nginx serving your files, open to anyone. `analytics` is the Umami tracking script, also open. `umami` is that same process with its dashboard behind an org login, and it needs Postgres. Those three share the place `web`, so they run on one serving device. `status` is Uptime Kuma behind an org login, on the place `monitor`, which can be a second serving device. A monitor on the same machine as the site cannot report that machine going down.

The Compose files are [docker-compose.yml](docker-compose.yml), [umami-compose.yml](umami-compose.yml), and [kuma-compose.yml](kuma-compose.yml). They read the host ports and the Umami secrets from [card.env](card.env). The sample page is [etc/index.html](etc/index.html). The card is [card.yml](card.yml).

## How

Five steps. Edit [card.env](card.env) before you start. The Compose files read that file.

### 1. Fetch

On the machine that will run the containers, fetch this card:

```bash
mkdir -p ~/website
curl -fsSL https://github.com/Edgible/cards/archive/refs/heads/main.tar.gz \
  | tar -xz --strip-components=3 -C ~/website cards-main/cards/website
```

### 2. Edit card.env

Open `~/website/card.env` and follow the comments in that file.

```bash
nano ~/website/card.env
```

### 3. Start the site and Umami

An existing `~/website/public/index.html` is left as it is. Place `web` runs these two Compose files.

```bash
mkdir -p ~/website/public
if [ ! -f ~/website/public/index.html ]; then
  cp ~/website/etc/index.html ~/website/public/index.html
fi
docker compose --project-name site --env-file ~/website/card.env -f ~/website/docker-compose.yml up -d
docker compose --project-name umami --env-file ~/website/card.env -f ~/website/umami-compose.yml up -d
```

### 4. Start the monitor

On the machine for place `monitor`, fetch this card the same way and edit `card.env` there. Then:

```bash
docker compose --project-name status --env-file ~/website/card.env -f ~/website/kuma-compose.yml up -d
```

When both places are the same machine, run that command in the same directory. That file reads `STATUS_PORT`.

### 5. Publish

`jq` reads each device's id out of `edgible device list`.

```bash
set -euo pipefail
set -a
. ~/website/card.env
set +a
device_id() {
  edgible device list --json | jq -er --arg name "$1" '
    map(select(.name == $name))
    | if length == 1 then .[0].id
      else error("need exactly one device named " + $name + " (" + (map(.status + " " + .id) | join(", ")) + ")")
      end
  '
}
web_id=$(device_id "$WEB_DEVICE")
monitor_id=$(device_id "$MONITOR_DEVICE")
edgible app create existing \
  --non-interactive \
  --name site \
  --port "$SITE_PORT" \
  --protocol https \
  --auth-modes none \
  --device-id "$web_id"
edgible app create existing \
  --non-interactive \
  --name analytics \
  --port "$UMAMI_PORT" \
  --protocol https \
  --auth-modes none \
  --device-id "$web_id"
edgible app create existing \
  --non-interactive \
  --name umami \
  --port "$UMAMI_PORT" \
  --protocol https \
  --auth-modes org \
  --device-id "$web_id"
edgible app create existing \
  --non-interactive \
  --name status \
  --port "$STATUS_PORT" \
  --protocol https \
  --auth-modes org \
  --device-id "$monitor_id"
edgible app list
```

`edgible app list` shows `site` and `analytics` with `none`, and `umami` and `status` with `org`.

## Getting Started

`edgible app list` prints each hostname.

`site` and `analytics` use `none`. Open the site hostname. You should see the sample page.

`umami` and `status` use `org`. Open each hostname, sign in, and create that app's admin on the first visit. The rest is in Umami and Uptime Kuma.
