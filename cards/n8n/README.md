# n8n

## Why

Moving work between systems usually goes to a hosted automation service, along with the keys to everything it touches. This card keeps that work on a machine you own. The editor asks for an org login. The webhook address stays open, because GitHub, Stripe, and `curl` cannot complete a browser login.

## What

Both apps are the place `workhorse`, so they stay on one serving device. They share port `5678`. The Compose file is [docker-compose.yml](docker-compose.yml). It runs Postgres and a task runner, and [init-data.sh](init-data.sh) sits next to it. The file reads the passwords, the host port, and `ORG_LABEL` from [card.env](card.env). The editor hostname is `n8n` plus that label. The webhook hostname is `n8n-hooks` plus that label. The card is [card.yml](card.yml).

## How

Five steps. Edit [card.env](card.env) before you start. [docker-compose.yml](docker-compose.yml) reads that file.

### 1. Fetch

On the machine that will run the containers, fetch this card:

```bash
mkdir -p ~/n8n
curl -fsSL https://github.com/Edgible/cards/archive/refs/heads/main.tar.gz \
  | tar -xz --strip-components=3 -C ~/n8n cards-main/cards/n8n
```

### 2. Edit card.env

Open `~/n8n/card.env` and follow the comments in that file.

```bash
nano ~/n8n/card.env
```

### 3. Start

```bash
docker compose --env-file ~/n8n/card.env -f ~/n8n/docker-compose.yml up -d
```

### 4. Create the owner

Open `http://127.0.0.1:5678` and create the n8n owner. This account stays on this machine.

### 5. Publish

`jq` reads that device's id out of `edgible device list`.

```bash
set -a
. ~/n8n/card.env
set +a
device_id=$(edgible device list --json | jq -er --arg name "$DEVICE" '
  map(select(.name == $name))
  | if length == 1 then .[0].id
    else error("need exactly one device named " + $name)
    end
')
edgible app create existing \
  --non-interactive \
  --name n8n \
  --port "$N8N_PORT" \
  --protocol https \
  --auth-modes org \
  --device-id "$device_id"
edgible app create existing \
  --non-interactive \
  --name n8n-hooks \
  --port "$N8N_PORT" \
  --protocol https \
  --auth-modes none \
  --device-id "$device_id"
edgible app list
```

`edgible app list` shows `n8n` with `org` and `n8n-hooks` with `none`. The editor hostname asks for an org login. The webhook hostname is open.
