# assistant

## Why

Asking questions of your own documents usually means handing those files to someone else's chat. This card keeps the documents and the model on a machine you own. The chat asks for an org login. The model asks for an API key, so another machine you own can call it, and a stranger cannot.

## What

Both apps are the place `desk`, so they stay on one serving device. `assistant` is Open WebUI on port `8088`, behind an org login. `ollama` is the chat model and the embedding model on port `11434`, behind an API key. Open WebUI calls Ollama on the machine, not through the public hostname. The document index stays inside Open WebUI.

Port `8088` is the host port. The website card already uses `8080` for nginx. The card starts from the Compose file Open WebUI publishes. The sample document is [sample-help.pdf](sample-help.pdf). The card is [card.yml](card.yml).

## How

The card lists the edits. [tailor.sh](tailor.sh) applies that list. The script does not contain a device name, a hostname, or a password. It exits if an expected edit is not in the file afterwards. Running it again is safe.

On the machine that will run the containers, fetch the Compose file Open WebUI publishes, the sample document, and the script:

```bash
mkdir -p ~/assistant
curl -fsSL https://raw.githubusercontent.com/open-webui/open-webui/main/docker-compose.yaml -o ~/assistant/docker-compose.yaml
curl -fsSL https://raw.githubusercontent.com/Edgible/cards/main/cards/assistant/sample-help.pdf -o ~/assistant/sample-help.pdf
curl -fsSL https://raw.githubusercontent.com/Edgible/cards/main/cards/assistant/tailor.sh -o ~/assistant-tailor.sh
bash ~/assistant-tailor.sh ~/assistant
```

Start the containers, then pull the models. `qwen2.5:7b` is the chat model. `nomic-embed-text` is the embedding model. The pulls are large and stay on this machine.

```bash
docker compose -f ~/assistant/docker-compose.yaml up -d
docker exec ollama ollama pull qwen2.5:7b
docker exec ollama ollama pull nomic-embed-text
```

Publish the two ports. Both apps are place `desk`, so one device name covers both. Replace `NAME` with the serving device from `edgible device list`. [card-publish.py](../../tools/card-publish.py) reads the card and runs `edgible app create existing` once per app. The organization id comes from the logged-in CLI.

```bash
curl -fsSL https://raw.githubusercontent.com/Edgible/cards/main/cards/assistant/card.yml -o ~/assistant-card.yml
curl -fsSL https://raw.githubusercontent.com/Edgible/cards/main/tools/card-publish.py -o ~/card-publish.py
python3 ~/card-publish.py ~/assistant-card.yml --device NAME
edgible app list
```

`edgible app list` shows `assistant` with `org` and `ollama` with `api-key`. Open the assistant hostname. Sign in with `org`, then create the Open WebUI admin on the first visit. In **Admin Settings**, then **Documents**, set the embedding engine to Ollama and the model to `nomic-embed-text`. In **Workspace**, then **Knowledge**, create a collection and upload `sample-help.pdf`. Wait until processing finishes. Attach that collection to the chat model under **Workspace**, then **Models**.

Ask: what are the support hours? The answer is the sentence in the sample: support hours are weekdays 9 to 5. Your own PDFs are the same steps. They are not part of the card.
