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

Check this machine before anything starts. The check reads `card.env` and looks for what the card would collide with: a host port, a container name, a Compose project, a leftover volume, a device name, or an app name. Each conflict prints its remedy. The report ends with those remedies as lines to paste into a shell: they fill empty secrets and change ports in `card.env`, keeping the old copy as `card.env.bak`. A line that stops or deletes something starts with `#`, so it runs only if you remove the `#`. Run the check again until it says `no conflicts`. It needs `python3` and Docker, and it uses `edgible` when that is installed.

```bash
curl -fsSLo check-env.py https://raw.githubusercontent.com/Edgible/cards/main/tools/check-env.py
python3 check-env.py litellm
```

### 4. Start

```bash
docker compose --env-file litellm/card.env -f litellm/docker-compose.yml up -d --wait
```

`--wait` returns when each service is running, and healthy when it has a healthcheck. A healthcheck comes from the Compose file or from the image. `ps` shows `(healthy)` in the status of each service that has one:

```bash
docker compose --env-file litellm/card.env -f litellm/docker-compose.yml ps
```

If `--wait` stops with `unhealthy`, `logs <service>` with the same `--env-file` and `-f` usually says why.

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

## Verify

`edgible app list` prints each hostname. Each app answers the way its auth mode says: `none` with the app, `org` with a redirect to the Edgible sign-in, and `api-key` with `401` until a key is sent. This checks the card. The rest of each app's setup is in that app's docs.

`litellm` uses `org`.

```bash
curl -sS -o /dev/null -w '%{http_code} %{redirect_url}\n' "https://<litellm hostname>"
```

That prints `302` and an `edgible.com/application-access/` address, so the org sign-in is in front. Open the hostname in a browser and sign in. The Admin UI username is `admin` and the password is `LITELLM_MASTER_KEY`. Create a team, then a virtual key for that team. The key is shown once. The rest of the setup is in the [LiteLLM docs](https://docs.litellm.ai).

`litellm-api` uses `none`.

```bash
curl -fsS "https://<litellm-api hostname>/v1/chat/completions" \
  -H "Authorization: Bearer sk-<virtual-key>" \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5","messages":[{"role":"user","content":"Say hello in five words."}]}'
```

A short reply means the proxy, the key, and the model work.

## Tear down

Four steps, in this order. Step 1 runs wherever `edgible` is logged in. Steps 2 to 4 run on the machine that runs the containers. Steps 2 and 3 read `card.env`, so keep it until step 4.

### 1. Unpublish

Delete the apps first, so no hostname points at a stopped container, and the names are free if you set the card up again.

```bash
edgible app delete litellm --yes
edgible app delete litellm-api --yes
```

### 2. Stop

This stops and removes the containers. The volumes stay, so Start brings the card back with its data.

```bash
docker compose --env-file litellm/card.env -f litellm/docker-compose.yml down
```

### 3. Delete the data

Skip this step to keep the data. It cannot be undone. The loop first copies each volume to a `.tgz` file in this directory. The containers are stopped, so each copy is whole.

```bash
for volume in $(docker volume ls -q --filter label=com.docker.compose.project=litellm); do
  docker run --rm -v "$volume:/data:ro" -v "$PWD:/backup" alpine tar -czf "/backup/$volume.tgz" -C /data .
done
docker compose --env-file litellm/card.env -f litellm/docker-compose.yml down --volumes
```

To bring a copy back, keep the `card.env` it was made with, because the databases in it expect those passwords. `create` makes the containers and the volumes without starting them. Unpack each copy into its volume, then Start.

```bash
docker compose --env-file litellm/card.env -f litellm/docker-compose.yml create
docker run --rm -v "<volume>:/data" -v "$PWD:/backup" alpine tar -xzf "/backup/<volume>.tgz" -C /data
```

### 4. Remove the card

`card.env` holds the passwords, and `card.env.bak` holds the copy from before the check edited it. If you kept the volumes in step 3, keep `card.env` too. The databases in those volumes expect its passwords.

```bash
rm -rf litellm
```
