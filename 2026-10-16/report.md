# edgible-cards skill evals, 2026-10-16

0 of 1 held-out prompts pass. Skill from card-kit `a2dd494`, `claude` 2.1.296 (Claude Code). Answering sessions: read-only, MCP tools: edgible find and describe.

| Prompt | Result | Skill loaded | expect | must_not broken | Principles missed |
| --- | --- | --- | --- | --- | --- |
| pocket-shutdown | FAIL | no (WRONG) | 1/3 | 0 | 2 |

## Details

### pocket-shutdown: FAIL
- Missed: two or three bookmark apps that keep page copies, with a recommendation. Only one app, linkding, is offered ('Edgible has one tested match'); it is link-only by default, with page copies only via the -plus image.
- Missed: asks about importing from Pocket. It explains the Pocket export/import and says 'I haven't tested it with a Pocket file', but it asks no question about importing. Its three questions cover page copies, phone use and hostname.
- Principle missed: Gives honest options side by side, including hosted ones where they fit, and states the upkeep of self-hosting.. It presents a single option with no hosted alternatives. It mentions backups but gives no comparison.
- Principle missed: Chooses each hostname's auth mode by who uses it: org only for the person's own team; members, customers, or the public use the app's own accounts.. It uses auth 'none' with the app's own login, even though the audience is the user and their team and phone apps need to connect. This is defensible for phone apps, but it does not weigh org auth for team sharing.
- Would be better: Offer two or three self-hosted options that keep page copies (for example linkding-plus, Linkwarden, Wallabag) with a clear recommendation, and ask whether to import the Pocket export.

## What would make answers better

- pocket-shutdown: Offer two or three self-hosted options that keep page copies (for example linkding-plus, Linkwarden, Wallabag) with a clear recommendation, and ask whether to import the Pocket export.
