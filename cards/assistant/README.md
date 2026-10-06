# assistant

## Why

Asking questions of your own documents usually means handing those files to someone else's chat. This card keeps the documents and the model on a machine you own. The chat asks for an org login. The model asks for an API key, so another machine you own can call it, and a stranger cannot.

## What

Both apps are the place `desk`, so they stay on one serving device. `assistant` is Open WebUI on port `8088`, behind an org login. `ollama` is the chat model and the embedding model on port `11434`, behind an API key. Open WebUI calls Ollama on the machine, not through the public hostname. The document index stays inside Open WebUI.

Port `8088` is the host port. The website card already uses `8080` for nginx. There is no upstream Compose file that publishes both this way, so `docker-compose.yml` sits next to this card. The sample document is [sample-help.pdf](sample-help.pdf). The card is [card.yml](card.yml).

## How

Nothing on the card needs editing, so there is no `tailor.sh`. On the machine that will run the containers:

```bash
mkdir -p ~/assistant
curl -fsSL https://raw.githubusercontent.com/Edgible/cards/main/cards/assistant/docker-compose.yml -o ~/assistant/docker-compose.yml
curl -fsSL https://raw.githubusercontent.com/Edgible/cards/main/cards/assistant/sample-help.pdf -o ~/assistant/sample-help.pdf
docker compose -f ~/assistant/docker-compose.yml up -d
docker exec ollama ollama pull qwen2.5:7b
docker exec ollama ollama pull nomic-embed-text
```

`qwen2.5:7b` is the chat model. `nomic-embed-text` is the embedding model. The pulls are large and stay on this machine.

Open the assistant after it is published. Sign in with `org`, then create the Open WebUI admin on the first visit. In **Admin Settings**, then **Documents**, set the embedding engine to Ollama and the model to `nomic-embed-text`. In **Workspace**, then **Knowledge**, create a collection and upload `sample-help.pdf`. Wait until processing finishes. Attach that collection to the chat model under **Workspace**, then **Models**.

Ask: what are the support hours? The answer is the sentence in the sample: support hours are weekdays 9 to 5. Your own PDFs are the same steps. They are not part of the card.
