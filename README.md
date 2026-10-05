# cards

Edgible Cards

`cards/` holds the patterns. `tools/` holds the schema and the scripts. A directory under `cards/` that contains `card.yml` is one card. [tools/card.schema.json](tools/card.schema.json) is the source of truth for that file. [tools/card-to-stack.py](tools/card-to-stack.py) writes a stack file from a card. [tools/card-image.py](tools/card-image.py) writes `card-light.svg` and `card-dark.svg` from the same file.

- [website](cards/website/README.md)
- [n8n](cards/n8n/README.md)

What each file in `tools/` does is [tools/README.md](tools/README.md).

## Publish a card

A card is published when a maintainer merges a pull request into `main`. Push the branch to your fork. Do not push to `main` on this repo.

The directory name under `cards/` is the pattern name, and it is unique. `cards/website/card.yml` is the website card. `metadata.name` is `website`.

Check the name before you add a directory:

```bash
gh api repos/Edgible/cards/contents/cards/n8n --jq .name
```

A 404 means `cards/n8n/` is free. A result means that name is taken. Edit the card that is already there, or pick a name that says how yours differs, such as `n8n-sqlite`.

The commands below use `desk` for a name that is free. On your fork:

```bash
mkdir -p cards/desk
```

Write `cards/desk/card.yml` so `metadata.name` is `desk` and the file satisfies [tools/card.schema.json](tools/card.schema.json). Leave out `deviceName`, `deviceId`, `organization`, hostnames, passwords, and volume data.

Write `cards/desk/README.md` in your own words: what problem this pattern solves, and anything a person should know before they run it. Leave the same details out of that file. The schema does not check it.

A picture is optional and is not part of the schema. Draw it from the card:

```bash
python3 tools/card-image.py cards/desk
```

That writes `card-light.svg` and `card-dark.svg` beside `card.yml`. If a `what` line does not fit, shorten it and run the command again. If the Compose file is not already public, put it next to `card.yml` and set `compose` to the raw URL it will have on `main`:

```
https://raw.githubusercontent.com/Edgible/cards/main/cards/desk/docker-compose.yml
```

Check the file. This needs the `pyyaml` and `jsonschema` packages.

```bash
python3 -c '
import json, sys
from pathlib import Path
import yaml
from jsonschema import Draft202012Validator
path = Path(sys.argv[1])
schema = json.loads(Path("tools/card.schema.json").read_text())
card = yaml.safe_load(path.read_text())
if card["metadata"]["name"] != path.parent.name:
    sys.exit("metadata.name must match the directory name")
Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER).validate(card)
print("ok")
' cards/desk/card.yml
```

`ok` means the file matches the schema and the directory name. Open a pull request. A maintainer merges it onto `main`. That merge is the publish. An update to a card that already exists is a pull request that changes that `card.yml`, and a maintainer decides whether the change belongs there.
