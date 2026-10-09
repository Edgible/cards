# litellm

## Why

Several apps calling a model usually share one provider key, and nothing on the machine records who spent it. This card keeps the model on a machine you own and puts a gateway in front of it. The admin asks for an org login. The API hostname is open, because a caller sends a LiteLLM virtual key as `Authorization: Bearer`.

## What

Both apps are the place `lab`, so they stay on one serving device. They share port `4000`. `litellm` is the admin UI. `litellm-api` is the OpenAI-compatible proxy on that same process. Ollama and Postgres run in the Compose file and are not published.

The Compose file is [docker-compose.yml](docker-compose.yml). The model list is [config.yaml](config.yaml). It reads the host port and the secrets from [card.env](card.env). The gateway calls Ollama at `http://ollama:11434` on the Compose network. The model name callers use is `qwen2.5`. The card is [card.yml](card.yml).

## How

Six steps. Edit [card.env](card.env) before you start. [docker-compose.yml](docker-compose.yml) reads that file.

### 1. Fetch

On the machine that will run the containers, fetch this card. Running this again replaces `card.env`, including the device name and any password you filled in.

```bash
mkdir -p litellm
curl -fsSL https://github.com/Edgible/cards/archive/refs/heads/main.tar.gz \
  | tar -xz --strip-components=3 -C litellm cards-main/cards/litellm
```

### 2. Edit card.env

Open `litellm/card.env` and follow the comments in that file.

```bash
nano litellm/card.env
```

### 3. Check

Check this machine before anything starts. The check reads `card.env` and looks for what the card would collide with: a host port, a container name, a Compose project, a leftover volume, a device name, or an app name. Each conflict prints its remedy. Fix them and run the check again until it says `no conflicts`. It needs `python3` and Docker, and it uses `edgible` when that is installed.

```bash
curl -fsSLo check-env.py https://raw.githubusercontent.com/Edgible/cards/main/tools/check-env.py
python3 check-env.py litellm
```

### 4. Start

```bash
docker compose --env-file litellm/card.env -f litellm/docker-compose.yml up -d
```

### 5. Pull the model

`qwen2.5:7b` is the chat model. The pull is large and stays on this machine.

```bash
docker exec litellm-ollama ollama pull qwen2.5:7b
```

### 6. Publish

`jq` reads that device's id out of `edgible device list`.

```bash
set -euo pipefail
set -a
. litellm/card.env
set +a
device_id=$(edgible device list --json | jq -er --arg name "$DEVICE" '
  map(select(.name == $name))
  | if length == 1 then .[0].id
    else error("need exactly one device named " + $name + " (" + (map(.status + " " + .id) | join(", ")) + ")")
    end
')
edgible app create existing \
  --non-interactive \
  --name litellm \
  --port "$LITELLM_PORT" \
  --protocol https \
  --auth-modes org \
  --device-id "$device_id"
edgible app create existing \
  --non-interactive \
  --name litellm-api \
  --port "$LITELLM_PORT" \
  --protocol https \
  --auth-modes none \
  --device-id "$device_id"
edgible app list
```

`edgible app list` shows `litellm` with `org` and `litellm-api` with `none`.

## Getting Started

`edgible app list` prints each hostname.

`litellm` uses `org`. Open that hostname and sign in. The Admin UI username is `admin` and the password is `LITELLM_MASTER_KEY`. Create a team, then a virtual key for that team. The key is shown once.

`litellm-api` uses `none`. Call it with the virtual key.

```bash
curl -fsS "https://<hostname>/v1/chat/completions" \
  -H "Authorization: Bearer sk-<virtual-key>" \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5","messages":[{"role":"user","content":"Say hello in five words."}]}'
```

A short reply means the key worked.
