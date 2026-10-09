# tools

These files are the machinery for any card. A directory under `cards/` is one card. Nothing in here is a card.

## card.schema.json

The source of truth for `card.yml`. A card matches this schema or it does not. It requires the application fields, allows `none`, `org`, or `api-key`, and requires protocol `https`. It rejects `deviceName`, `deviceId`, and `organization`.

Check a file from the repo root. This needs the `pyyaml` and `jsonschema` packages. The command is in the [publish section](../README.md#publish-a-card).

## check-cards.py

Runs that check. With no arguments it checks every `cards/<name>/card.yml`. `metadata.name` must match the directory name. The pull request workflow runs this command. A failing check means the card does not match the schema.

```bash
python3 tools/check-cards.py
```

## card-image.py

Writes `images/card-light.svg` and `images/card-dark.svg` for a card. The picture lists the apps, ports, auth modes, and places. It draws no caller, no hostname, and no machine. The words come from the card. If a `what` line does not fit the row, the command fails and you shorten that line.

```bash
python3 tools/card-image.py cards/website
```

## check-env.py

Checks a fetched card against the machine it is about to run on. Run it after `card.env` is edited and before the containers start. The argument is the card directory. With no `-f`, it checks every `*compose*.yml` in that directory.

```bash
python3 tools/check-env.py cards/website
python3 tools/check-env.py cards/website -f kuma-compose.yml
```

Compose resolves each file with `card.env`, so the ports and names it checks are the ones `docker compose up` would use. It looks for empty required values, host ports already in use, container names already taken, Compose project names used by another file, volumes left by an earlier run, `DEVICE` values that match no device, and Edgible apps with the same name. Each conflict prints a remedy. A container, port, project, or volume from the same Compose file is that card already running, and is not a conflict. Exit 0 means no conflicts, 1 means at least one, and 2 means the check could not run.

It needs only `python3` and Docker. It uses `edgible` when that is installed and logged in. A card README fetches this one file with `curl` and runs it, because the card fetch does not include `tools/`.
