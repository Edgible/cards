# n8n

One n8n process, published twice. The editor is behind an org login. The webhook hostname is open, because GitHub, Stripe, and `curl` cannot complete a browser login.

Both apps are the place `workhorse`, so they stay on one serving device. They share port `5678`. The card starts from the Compose file n8n publishes, which runs Postgres and a task runner. The edits bind that port to loopback, replace the sample database passwords and the runner token, and point the editor URL and the webhook URL at the two hostnames this card publishes. [tailor.sh](tailor.sh) applies that list.

Fetch the gold `docker-compose.yml`, `.env`, and `init-data.sh` into one directory. Pass that directory and your org label. The label is the part of a hostname you already have between the first dot and `.edgible.com`. The script does not contain the label, a hostname, or a password.

```bash
bash tailor.sh ~/n8n "$org"
```

The card is [card.yml](card.yml).
