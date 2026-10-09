# cards

Edgible cards let a deployment pattern be shared and reproduced. A card records the programs, the images, the ports, the auth mode on each hostname, and which apps share a serving device. Someone else fetches that card, edits `card.env`, starts the containers, and publishes the apps. The card leaves out device names, hostnames, and the organization id, so the next person maps each place to a serving device they have.

Why cards exist, and what they promise, is in [ABOUT.md](ABOUT.md).

`cards/` holds the cards. A directory under `cards/` that contains `card.yml` is one card. The README in that directory is how you fetch the card, edit `card.env`, start the containers, and publish. [tools/card.schema.json](tools/card.schema.json) is the source of truth for `card.yml`. [tools/card-image.py](tools/card-image.py) writes `images/card-light.svg` and `images/card-dark.svg` from the same file.

- [website](cards/website/README.md)
- [n8n](cards/n8n/README.md)
- [assistant](cards/assistant/README.md)
- [litellm](cards/litellm/README.md)
- [accounts](cards/accounts/README.md)

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

Write `cards/desk/README.md` with five headings: Why, What, How, Verify, and Tear down. Copy the shape from a card like yours and change the names, so every card reads the same way.

Why is the problem this card solves. What is the apps and the places. How is how to fetch the card, edit `card.env`, check the machine, start the Compose file, and publish.

Verify comes after Publish. It checks the card, not the apps. Each app gets one check that its hostname answers the way its auth mode says: `none` with the app, `org` with a redirect to the Edgible sign-in, and `api-key` with `401` until a key is sent. Add the first sign-in when the app makes its admin on the first visit. End with a link to that app's docs.

Tear down is last, with the same four steps as every other card: Unpublish each app, Stop with `down`, Delete the data after copying each volume to a `.tgz`, and Remove the card.

A card holds what depends on Edgible or on another app in the card: hostnames, auth modes, devices, and how the apps reach each other. What is the same on any host belongs to the app: its users, its settings, and how to use it. Link to the app's docs. Do not copy them.

An app that must know its own URL builds it from `ORG_LABEL` in `card.env`, as the n8n card does: `https://<app>.${ORG_LABEL}.edgible.com` is the hostname Publish generates, so nothing changes after Publish. For a URL on your own domain, add an `<APP>_URL` override that wins over it, such as `${ACCOUNTS_URL:-https://accounts.${ORG_LABEL:?set ORG_LABEL in card.env}.edgible.com}`.

Leave device names, hostnames, organization ids, and passwords out of the README. The schema does not check it.

A picture is optional and is not part of the schema. Draw it from the card:

```bash
tools/run card-image cards/desk
```

That writes `images/card-light.svg` and `images/card-dark.svg`. If a `what` line does not fit, shorten it and run the command again. A sample file that the card hands you, such as a PDF or a page, goes in `etc/`. The Compose file the card runs sits next to `card.yml`. Its first setting is a top-level `name:`, the Compose project name. Pick one that says which card it is, because two Compose files with the same `name:` on one machine replace each other's containers.

Machine settings go in `card.env`. The Compose file reads that file. A later change to the upstream project is an update to this Compose file. Leave device names, hostnames, organization ids, and passwords out of the Compose file and out of `card.env` in git.

`card.yml` stays short because the tools read the rest from names. Follow these, and the check below tells you when a name is off. `<APP>` is the app name in capitals, with `-` written `_`.

| What | Name |
|---|---|
| The host port of an app | `<APP>_PORT` in `card.env`, set to the port in `card.yml`. Apps that are one process share the first one's variable, so list that app first. |
| The Compose file that runs an app | The one that reads `${<APP>_PORT`. |
| The serving device | `DEVICE` for a card with one place. `<PLACE>_DEVICE` for each place of a card with more. |
| The Compose project | A top-level `name:` in each Compose file. |
| The URL an app gives out | Built from `ORG_LABEL`, with an `<APP>_URL` override for your own domain. |
| A secret | Empty in git, with a `# Generate with: <command>` comment above it. The check on the machine fills it with that command. |
| A value the card cannot run without | `${VAR:?set VAR in card.env}` in the Compose file. |

Check the file. `tools/run` runs it in a container, so Docker is all it needs. The first run builds that container. The same check runs on the pull request.

```bash
tools/run check-cards cards/desk/card.yml
```

`ok` means the file matches the schema, the directory name, and the names in the table above. Open a pull request. A maintainer merges it onto `main`. That merge is the publish. An update to a card that already exists is a pull request that changes that `card.yml`, and a maintainer decides whether the change belongs there.


## License

Everything in this repo, the cards and the tools, is under the [MIT License](LICENSE). A card you contribute is shared under the same license. The apps a card runs keep their own licenses.
