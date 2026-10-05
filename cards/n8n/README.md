# n8n

## Why

Moving work between systems usually goes to a hosted automation service, along with the keys to everything it touches. This card keeps that work on a machine you own. The editor asks for an org login. The webhook address stays open, because GitHub, Stripe, and `curl` cannot complete a browser login.

## What

Both apps are the place `workhorse`, so they stay on one serving device. They share port `5678`. The card starts from the Compose file n8n publishes, which runs Postgres and a task runner. The card is [card.yml](card.yml).

## How

[tailor.sh](tailor.sh) applies the edits on the card. The script does not contain an org label, a hostname, or a password. It exits if an expected edit is not in the file afterwards. Running it again is safe.

The org label is the part of a hostname you already have between the first dot and `.edgible.com`. One published app is enough to read it. On the machine that will run the container:

```bash
mkdir -p ~/n8n
curl -fsSL https://raw.githubusercontent.com/n8n-io/n8n-hosting/main/docker-compose/withPostgres/docker-compose.yml -o ~/n8n/docker-compose.yml
curl -fsSL https://raw.githubusercontent.com/n8n-io/n8n-hosting/main/docker-compose/withPostgres/.env -o ~/n8n/.env
curl -fsSL https://raw.githubusercontent.com/n8n-io/n8n-hosting/main/docker-compose/withPostgres/init-data.sh -o ~/n8n/init-data.sh
chmod +x ~/n8n/init-data.sh
org=$(edgible app list --json | python3 -c '
import json, sys
apps = json.load(sys.stdin)
hosts = [h for app in apps for h in (app.get("hostnames") or [])]
if not hosts:
    sys.exit("need one published app so the org label is known")
print(hosts[0].split(".", 1)[1].removesuffix(".edgible.com"))
')
curl -fsSL https://raw.githubusercontent.com/Edgible/cards/main/cards/n8n/tailor.sh -o ~/n8n-tailor.sh
bash ~/n8n-tailor.sh ~/n8n "$org"
```
