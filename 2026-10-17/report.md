# edgible-cards skill evals, 2026-10-17

0 of 1 held-out prompts pass. Skill from card-kit `a2dd494`, `claude` 2.1.296 (Claude Code). Answering sessions: read-only, MCP tools: edgible find and describe.

| Prompt | Result | Skill loaded | expect | must_not broken | Principles missed |
| --- | --- | --- | --- | --- | --- |
| marketing-site-cost | FAIL | no (WRONG) | 1/3 | 0 | 1 |

## Details

### marketing-site-cost: FAIL
- Missed: asks whether the site is static or edited in a CMS. It asks about 'how often the content changes, and who edits it' and page count, features, and comfort with code, but never directly asks whether the site is static or CMS-edited.
- Missed: the wordpress card on a small cloud server for a CMS, with the upkeep stated. It mentions 'WordPress.com or shared hosting: about $3 to $8/month. It's more flexible but needs more upkeep.' It doesn't propose WordPress on a small cloud server. The VPS option is mentioned only as self-hosting.
- Principle missed: Asks at most two or three questions, and only ones whose answers change the recommendation.. It gives four checklist items and then asks for three more details (page count, features, comfort with code). That is too many.
- Would be better: Ask up front whether the site is static or edited through a CMS, then give one clear path for each case, with free static hosting for static and WordPress on a small cloud server for CMS with its upkeep stated, instead of a long menu and checklist.

## What would make answers better

- marketing-site-cost: Ask up front whether the site is static or edited through a CMS, then give one clear path for each case, with free static hosting for static and WordPress on a small cloud server for CMS with its upkeep stated, instead of a long menu and checklist.
