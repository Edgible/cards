# assistant

## Why

Asking questions of your own documents usually means handing those files to someone else's chat. This card keeps the documents and the model on a machine you own. The chat asks for an org login. The model asks for an API key, so another machine you own can call it, and a stranger cannot.

## What

Both apps are the place `desk`, so they stay on one serving device. `assistant` is Open WebUI on port `8088`, behind an org login. `ollama` is the chat model and the embedding model on port `11434`, behind an API key. Open WebUI calls Ollama on the machine, not through the public hostname. The document index stays inside Open WebUI.

Port `8088` is the host port. The website card already uses `8080` for nginx. The Compose file is [docker-compose.yml](docker-compose.yml). It reads the host ports from [card.env](card.env). The sample document is [etc/sample-help.pdf](etc/sample-help.pdf). The card is [card.yml](card.yml).

## How

Five steps. Edit [card.env](card.env) before you start. [docker-compose.yml](docker-compose.yml) reads the host ports from that file.

### 1. Fetch

On the machine that will run the containers, fetch this card:

```bash
mkdir -p assistant
curl -fsSL https://github.com/Edgible/cards/archive/refs/heads/main.tar.gz \
  | tar -xz --strip-components=3 -C assistant cards-main/cards/assistant
```

### 2. Edit card.env

Open `assistant/card.env` and follow the comments in that file.

```bash
nano assistant/card.env
```

### 3. Start

```bash
docker compose --env-file assistant/card.env -f assistant/docker-compose.yml up -d
```

### 4. Pull the models

`qwen2.5:7b` is the chat model. `nomic-embed-text` is the embedding model. The pulls are large and stay on this machine.

```bash
docker exec ollama ollama pull qwen2.5:7b
docker exec ollama ollama pull nomic-embed-text
```

### 5. Publish

`jq` reads that device's id out of `edgible device list`.

```bash
set -euo pipefail
set -a
. assistant/card.env
set +a
device_id=$(edgible device list --json | jq -er --arg name "$DEVICE" '
  map(select(.name == $name))
  | if length == 1 then .[0].id
    else error("need exactly one device named " + $name + " (" + (map(.status + " " + .id) | join(", ")) + ")")
    end
')
edgible app create existing \
  --non-interactive \
  --name assistant \
  --port "$ASSISTANT_PORT" \
  --protocol https \
  --auth-modes org \
  --device-id "$device_id"
edgible app create existing \
  --non-interactive \
  --name ollama \
  --port "$OLLAMA_PORT" \
  --protocol https \
  --auth-modes api-key \
  --device-id "$device_id"
edgible app list
```

`edgible app list` shows `assistant` with `org` and `ollama` with `api-key`.

## Getting Started

`edgible app list` prints each hostname.

`assistant` uses `org`. Open that hostname and sign in. The first visit creates the Open WebUI admin. The rest of the setup is in Open WebUI. Upload `sample-help.pdf` and ask what the support hours are. The answer is weekdays 9 to 5.

`ollama` uses `api-key`. Create a key. The secret is shown once. The app id is the one `edgible app list` prints for `ollama`.

```bash
edgible app api-keys create --app-id <ollama-app-id> --name caller
```

```bash
curl -fsS "https://<hostname>/api/tags" -H "Authorization: Bearer <secret>"
```

A list of models means the hostname accepted the key.
