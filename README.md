# cards

Edgible Cards

`cards/` holds the patterns. `tools/` holds the schema and the scripts. A directory under `cards/` that contains `card.yml` is one card. [tools/card.schema.json](tools/card.schema.json) is the source of truth for that file. [tools/card-to-stack.py](tools/card-to-stack.py) writes a stack file from a card. [tools/card-image.py](tools/card-image.py) writes `images/card-light.svg` and `images/card-dark.svg` from the same file.

- [website](cards/website/README.md)
- [n8n](cards/n8n/README.md)
- [assistant](cards/assistant/README.md)

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

Write `cards/desk/README.md` with three headings: Why, What, and How. Why is the problem this card solves. What is the apps and the places. How is how to fetch the card, edit `card.env`, and start the Compose file. Leave device names, hostnames, organization ids, and passwords out of that file. The schema does not check it.

A picture is optional and is not part of the schema. Draw it from the card:

```bash
python3 tools/card-image.py cards/desk
```

That writes `images/card-light.svg` and `images/card-dark.svg`. If a `what` line does not fit, shorten it and run the command again. A sample file that the card hands you, such as a PDF or a page, goes in `etc/`. The Compose file the card runs sits next to `card.yml`.

Machine settings go in `card.env`. The Compose file reads that file. A later change to the upstream project is an update to this Compose file. Leave device names, hostnames, organization ids, and passwords out of the Compose file and out of `card.env` in git.

Check the file. This needs the `pyyaml` and `jsonschema` packages. The same check runs on the pull request.

```bash
python3 tools/check-cards.py cards/desk/card.yml
```

`ok` means the file matches the schema and the directory name. Open a pull request. A maintainer merges it onto `main`. That merge is the publish. An update to a card that already exists is a pull request that changes that `card.yml`, and a maintainer decides whether the change belongs there.

