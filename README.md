# cards

Edgible cards let a deployment pattern be shared and reproduced. A card records the programs, the images, the ports, the auth mode on each hostname, and which apps share a serving device. Someone else fetches that card, edits `card.env`, starts the containers, and publishes the apps. The card leaves out device names, hostnames, and the organization id, so the next person maps each place to a serving device they have.

Why cards exist, and what they promise, is in [ABOUT.md](ABOUT.md).

Each top-level directory with a `card.yml` in it is one card. Its README is how you fetch the card, edit `card.env`, start the containers, and publish.

- [website](website/README.md)
- [n8n](n8n/README.md)
- [assistant](assistant/README.md)
- [litellm](litellm/README.md)
- [accounts](accounts/README.md)
- [ci](ci/README.md)

The format of a card, its conventions, and the tools that check it are in [Edgible/card-kit](https://github.com/Edgible/card-kit). Single-app starters to build a card from are in [Edgible/starters](https://github.com/Edgible/starters).

## Publish a card

A card is published when a maintainer merges a pull request into `main`. Push the branch to your fork. Do not push to `main` on this repo.

The directory name is the pattern name, and it is unique. `website/card.yml` is the website card, and its `metadata.name` is `website`. Check the name before you add a directory:

```bash
gh api repos/Edgible/cards/contents/n8n --jq .name
```

A 404 means `n8n/` is free. A result means that name is taken. Edit the card that is already there, or pick a name that says how yours differs, such as `n8n-sqlite`.

The commands below use `desk` for a name that is free. Clone your fork and [card-kit](https://github.com/Edgible/card-kit) side by side, then work from your fork's root:

```bash
git clone https://github.com/Edgible/card-kit ../card-kit
mkdir -p desk
```

Write `desk/card.yml`, `desk/README.md`, `desk/card.env`, and the Compose file the way [the card format](https://github.com/Edgible/card-kit#what-a-card-is) describes. Copy the shape from a card here that is like yours and change the names, so every card reads the same way. A [starter](https://github.com/Edgible/starters) for each app in your pattern is a good place to begin.

Check it. `run` uses Docker, so Docker is all it needs. The same check runs on the pull request.

```bash
../card-kit/run check-cards desk/card.yml
```

`ok` means the file matches the schema, the directory name, and [the conventions](https://github.com/Edgible/card-kit#conventions). A picture is optional:

```bash
../card-kit/run card-image desk
```

Open a pull request. A maintainer merges it onto `main`. That merge is the publish. An update to a card that already exists is a pull request that changes that card, and a maintainer decides whether the change belongs there.

## Contributing

How to add a card, fix one, or ask for one is in [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Everything in this repo is under the [MIT License](LICENSE). A card you contribute is shared under the same license. The apps a card runs keep their own licenses.
