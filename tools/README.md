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
