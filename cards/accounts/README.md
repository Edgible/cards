# accounts

## Why

A site or an app with members needs sign-up, sign-in, a reset for a lost password, and a list of who signed up. That list usually lives with a service someone else runs. This card keeps it on a machine you own. Your visitors sign in on the open hostname. You manage them on a console behind an org login.

The org login protects pages for you and your team. This card is the login for the people who use what you built.

## What

`accounts` is Logto, open to anyone. It serves the sign-in and sign-up pages, and it is the OpenID Connect provider your apps send visitors to. `accounts-admin` is that same process with the Logto console behind an org login. In the console you add your apps, choose how visitors sign in, and manage users. Both share the place `identity`, so they run on one serving device.

Logto keeps all its state in Postgres: users, apps, sign-in settings, sessions, and the keys that sign its tokens. That is the one volume `logto-db-data`. The Logto container holds nothing, and a `pg_dump` of the `logto` database is the whole install. Each user has a `customData` JSON object for small facts about that person, such as a plan or a preference. Keep secrets and the records of your app out of it.

The Compose file is [docker-compose.yml](docker-compose.yml). It reads the host ports, the database password, and the public URLs from [card.env](card.env). Each start seeds an empty database and applies the database changes for the Logto version in that file. The card is [card.yml](card.yml).

## How

Five steps. Edit [card.env](card.env) before you start. The Compose file reads that file.

### 1. Fetch

On the machine that will run the containers, fetch this card. Running this again replaces `card.env`, including the device name, the password, and the URLs you filled in.

```bash
mkdir -p accounts
curl -fsSL https://github.com/Edgible/cards/archive/refs/heads/main.tar.gz \
  | tar -xz --strip-components=3 -C accounts cards-main/cards/accounts
```

### 2. Edit card.env

Open `accounts/card.env` and follow the comments in that file. Leave `LOGTO_ENDPOINT` and `LOGTO_ADMIN_ENDPOINT` empty until step 5, unless you already know both hostnames.

```bash
nano accounts/card.env
```

### 3. Start

```bash
docker compose --project-name accounts --env-file accounts/card.env -f accounts/docker-compose.yml up -d --wait
```

### 4. Publish

`jq` reads the device id out of `edgible device list`.

```bash
set -euo pipefail
set -a
. accounts/card.env
set +a
identity_id=$(edgible device list --json | jq -er --arg name "$IDENTITY_DEVICE" '
  map(select(.name == $name))
  | if length == 1 then .[0].id
    else error("need exactly one device named " + $name + " (" + (map(.status + " " + .id) | join(", ")) + ")")
    end
')
edgible app create existing \
  --non-interactive \
  --name accounts \
  --port "$ACCOUNTS_PORT" \
  --protocol https \
  --auth-modes none \
  --device-id "$identity_id"
edgible app create existing \
  --non-interactive \
  --name accounts-admin \
  --port "$ACCOUNTS_ADMIN_PORT" \
  --protocol https \
  --auth-modes org \
  --device-id "$identity_id"
edgible app list
```

`edgible app list` shows `accounts` with `none` and `accounts-admin` with `org`.

### 5. Record the hostnames

Logto writes its own public URL into every redirect and token. Until it knows both hostnames, it uses `localhost`. Put the two hostnames from `edgible app list` into `accounts/card.env`, with `https://` in front:

```bash
LOGTO_ENDPOINT=https://<accounts hostname>
LOGTO_ADMIN_ENDPOINT=https://<accounts-admin hostname>
```

Then start the card again. Compose recreates the Logto container with the new URLs. The database stays.

```bash
docker compose --project-name accounts --env-file accounts/card.env -f accounts/docker-compose.yml up -d --wait
```

## Getting Started

`accounts` uses `none`. The issuer in its OpenID configuration is the hostname you recorded.

```bash
curl -fsS "https://<accounts hostname>/oidc/.well-known/openid-configuration" | jq -r .issuer
```

That prints `https://<accounts hostname>/oidc`. If it prints `localhost`, step 5 did not take.

`accounts-admin` uses `org`. Open `https://<accounts-admin hostname>/console` and sign in. The first visit creates the Logto admin. The rest of the setup is in Logto: add an application for your site, and that application's settings give you the values your site needs to send visitors to `accounts`.
