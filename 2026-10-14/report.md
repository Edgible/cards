# edgible-cards skill evals, 2026-10-14

1 of 2 held-out prompts pass. Skill from card-kit `b3a4fb1`, `claude` 2.1.296 (Claude Code). Answering sessions: read-only, MCP tools: edgible find and describe.

| Prompt | Result | Skill loaded | expect | must_not broken | Principles missed |
| --- | --- | --- | --- | --- | --- |
| sensitive-photos | FAIL | no (WRONG) | 3/3 | 0 | 1 |
| negative-landlord-email | pass | no (right) | 1/1 | 0 | 0 |

## Details

### sensitive-photos: FAIL
- Principle missed: Gives honest options side by side, including hosted ones where they fit, and states the upkeep of self-hosting.. It offers only Immich, with no alternatives. It mentions the backup responsibility and "prompt updates" but does not describe the upkeep in full.
- Would be better: Present a short side-by-side of options, including a local-only approach with no server and an end-to-end-encrypted hosted service, and state the ongoing upkeep of self-hosting more plainly.

### negative-landlord-email: pass
- Would be better: Nothing essential is missing; it could be slightly stronger by naming the two-week duration as a clear request deadline or mentioning tenant repair rights, but it fully answers the request.

## What would make answers better

- sensitive-photos: Present a short side-by-side of options, including a local-only approach with no server and an end-to-end-encrypted hosted service, and state the ongoing upkeep of self-hosting more plainly.
- negative-landlord-email: Nothing essential is missing; it could be slightly stronger by naming the two-week duration as a clear request deadline or mentioning tenant repair rights, but it fully answers the request.
