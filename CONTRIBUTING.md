# Contributing a card

There are three ways to help: add a card, fix one, or ask for one. The card format and its tools are in [Edgible/card-kit](https://github.com/Edgible/card-kit). What is written there wins over anything here.

## Ask for a card

Open an issue from the **Card request** template. Say what the pattern is for, which apps it joins, and how they reach each other. If each app has a [starter](https://github.com/Edgible/starters), link it. An app with no starter yet is better asked for there.

## Add or fix a card

The steps are in the README's [Publish a card](README.md#publish-a-card): check the name, fork, write the card from its starters, run `check-cards`, and open a pull request from your fork. Never push to `main`.

Before the pull request:

- **Test it** with `test-card` on your own serving device when you can, and commit the `test.yml` it writes. A card does not have to carry one, but a reviewer trusts a card that does. That needs Docker, an Edgible account with a serving device, and the `edgible` CLI logged in:

  ```bash
  python3 ../card-kit/test-card.py <name> --device <your-device>
  ```

- **Check nothing private is left:** no device name, hostname, organization id, password, or your own domain, in any file.

For a fix, say what was wrong and how you know it is fixed.

## What happens next

A maintainer reviews the checklist in the pull request template, and decides whether a change to an existing card belongs there. The merge is the publish.

## Made with an AI agent

That is welcome. The [edgible-cards skill](https://github.com/Edgible/card-kit/tree/main/skills/edgible-cards) follows this file. Say in the pull request that an agent made it. You are still the one asking for the merge, so read what it wrote.

## Licence

This repository is [MIT](LICENSE). By contributing, you agree that your contribution is under the same licence. The apps a card runs keep their own licences.
