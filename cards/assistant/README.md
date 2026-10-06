# assistant

## Why

Asking questions of your own documents usually means handing those files to someone else's chat. This card keeps the documents and the model on a machine you own. The chat asks for an org login. The model asks for an API key, so another machine you own can call it, and a stranger cannot.

## What

Both apps are the place `desk`, so they stay on one serving device. `assistant` is Open WebUI on port `8088`, behind an org login. `ollama` is the chat model and the embedding model on port `11434`, behind an API key. Open WebUI calls Ollama on the machine, not through the public hostname. The document index stays inside Open WebUI.

Port `8088` is the host port. The website card already uses `8080` for nginx. The card starts from the Compose file Open WebUI publishes. The sample document is [etc/sample-help.pdf](etc/sample-help.pdf). The card is [card.yml](card.yml).

## How

Five steps. Edit [card.env](card.env) before [tailor.sh](tailor.sh). The script reads the ports from that file. It does not contain a device name, a hostname, or a password. It exits if an expected edit is missing. Running it again is safe.

### 1. Fetch

On the machine that will run the containers, fetch this card, then the Compose file Open WebUI publishes. That Compose file is not in the card directory.

```bash
mkdir -p ~/assistant
curl -fsSL https://github.com/Edgible/cards/archive/refs/heads/main.tar.gz \
  | tar -xz --strip-components=3 -C ~/assistant cards-main/cards/assistant
curl -fsSL https://raw.githubusercontent.com/open-webui/open-webui/main/docker-compose.yaml \
  -o ~/assistant/docker-compose.yaml
```

### 2. Edit card.env

Open `~/assistant/card.env` and follow the comments in that file.

Linux:

```bash
nano ~/assistant/card.env
```

macOS:

```bash
open -e ~/assistant/card.env
```

### 3. Tailor and start

```bash
bash ~/assistant/tailor.sh ~/assistant
docker compose -f ~/assistant/docker-compose.yaml up -d
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
set -a
. ~/assistant/card.env
set +a
device_id=$(edgible device list --json | jq -er --arg name "$DEVICE" '
  map(select(.name == $name))
  | if length == 1 then .[0].id
    else error("need exactly one device named " + $name)
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

`edgible app list` shows `assistant` with `org` and `ollama` with `api-key`. Open the assistant hostname. Sign in with `org`, then create the Open WebUI admin on the first visit. In **Admin Settings**, then **Documents**, set the embedding engine to Ollama and the model to `nomic-embed-text`. In **Workspace**, then **Knowledge**, create a collection and upload `sample-help.pdf`. Wait until processing finishes. Attach that collection to the chat model under **Workspace**, then **Models**.

Ask: what are the support hours? The answer is the sentence in the sample: support hours are weekdays 9 to 5. Your own PDFs are the same steps. They are not part of the card.
