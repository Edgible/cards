# website

## Why

A site, the editor for its pages, the count of who read it, and a check that it is still up are usually services someone else runs. This card keeps them on machines you own. Strangers can open the site and the tracking script. The editor, the dashboard, and the monitor ask for an org login.

## What

`site` is a Vite React app, open to anyone. nginx serves the static build. The sample page is in those files, so the same build can be uploaded to S3. On this card, nginx forwards `/api` to Strapi, and a reload shows an edit from the editor. `strapi` is the editor behind an org login, and it needs Postgres. The editor stays on its own hostname. `analytics` is the Umami tracking script, also open. `umami` is that same process with its dashboard behind an org login, and it needs its own Postgres. Those four share the place `web`, so they run on one serving device. `status` is Uptime Kuma behind an org login, on the place `monitor`, which can be a second serving device. A monitor on the same machine as the site cannot report that machine going down.

The Compose files are [docker-compose.yml](docker-compose.yml), [umami-compose.yml](umami-compose.yml), and [kuma-compose.yml](kuma-compose.yml). They read the host ports and the secrets from [card.env](card.env). The Vite app is [site](site). The Strapi project is [strapi](strapi). The card is [card.yml](card.yml).

## How

Five steps. Edit [card.env](card.env) before you start. The Compose files read that file.

### 1. Fetch

On the machine that will run the containers, fetch this card. Running this again replaces `card.env`, including the device name and any password you filled in.

```bash
mkdir -p website
curl -fsSL https://github.com/Edgible/cards/archive/refs/heads/main.tar.gz \
  | tar -xz --strip-components=3 -C website cards-main/cards/website
```

### 2. Edit card.env

Open `website/card.env` and follow the comments in that file.

```bash
nano website/card.env
```

### 3. Start the site and Umami

Place `web` runs these two Compose files. The Vite site and Strapi images are built from this card.

```bash
docker compose --project-name site --env-file website/card.env -f website/docker-compose.yml up -d --build
docker compose --project-name umami --env-file website/card.env -f website/umami-compose.yml up -d
```

### 4. Start the monitor

On the machine for place `monitor`, fetch this card the same way and edit `card.env` there. Then:

```bash
docker compose --project-name status --env-file website/card.env -f website/kuma-compose.yml up -d
```

When both places are the same machine, run that command in the same directory. That file reads `STATUS_PORT`.

### 5. Publish

`jq` reads each device's id out of `edgible device list`.

```bash
set -euo pipefail
set -a
. website/card.env
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
  --name strapi \
  --port "$STRAPI_PORT" \
  --protocol https \
  --auth-modes org \
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

`edgible app list` shows `site` and `analytics` with `none`, and `strapi`, `umami`, and `status` with `org`.

## Getting Started

`edgible app list` prints each hostname.

`site` uses `none`. The page contains `Served from a box I own.` That sentence is the sample Page in Strapi. Edit it in the editor and reload the site.

```bash
curl -fsS "https://<hostname>"
```

`strapi` uses `org`. Open that hostname and sign in. The first visit creates the Strapi admin. The rest of the setup is in Strapi.

`analytics` uses `none`. The tracker script comes back, not an org login page.

```bash
curl -fsS "https://<hostname>/script.js"
```

`umami` uses `org`. Open that hostname and sign in. The first visit creates the Umami admin. The rest of the setup is in Umami.

`status` uses `org`. Open that hostname and sign in. The first visit creates the Uptime Kuma admin. The rest of the setup is in Uptime Kuma.
