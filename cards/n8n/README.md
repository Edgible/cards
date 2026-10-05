# n8n

One n8n process, published twice. The editor is behind an org login. The webhook hostname is open, because GitHub, Stripe, and `curl` cannot complete a browser login.

Both apps are the place `workhorse`, so they stay on one serving device. They share port `5678`. The card starts from the Compose file n8n publishes, which runs Postgres and a task runner. [tailor.sh](tailor.sh) applies the edits on the card. The script does not contain an org label, a hostname, or a password.

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

The card is [card.yml](card.yml).
