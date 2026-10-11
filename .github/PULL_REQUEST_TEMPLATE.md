## What

<!-- A new card, or a change to one. Say whether it is an app card or a pattern.
     A new app card: the app, what it is for, and a link to it. A new pattern: what it is for, its apps and places, and the app cards it was built from.
     A change: what was wrong. Link an issue if there is one. -->

## Test

<!-- The last lines of `python3 ../card-kit/test-card.py <name> --device <your-device>`, from `result:`.
     Required for an app card. Leave out device names, hostnames, and anything secret. -->

```
result:
```

## Review

From [Reviewing a card](https://github.com/Edgible/cards/blob/main/README.md#reviewing-a-card). Tick what you checked.

- [ ] Default passwords are changed or generated, and the README says how to sign in the first time.
- [ ] Every secret is empty in git, with a `# Generate with:` comment.
- [ ] The auth mode of each hostname suits its callers, by the README's table.
- [ ] The README says where the data lives, and Tear down backs it up before deleting it.
- [ ] `test.yml` passes, and its images are the ones in the Compose files. An app card must have one.
- [ ] Nothing names a device, a hostname, or an organization.
- [ ] `check-cards --fresh` passes.
- [ ] An app card's app is not on [What is not an app card](https://github.com/Edgible/cards/blob/main/README.md#what-is-not-an-app-card).

- [ ] An AI agent made this pull request, and I have read what it wrote.
