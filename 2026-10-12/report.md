# edgible-cards skill evals, 2026-10-13

2 of 2 held-out prompts pass. Skill from card-kit `b39a7bb`, `claude` 2.1.296 (Claude Code). Answering sessions: read-only, MCP tools: edgible find and describe.

| Prompt | Result | Skill loaded | expect | must_not broken | Principles missed |
| --- | --- | --- | --- | --- | --- |
| physio-clinic | pass | yes (right) | 4/4 | 0 | 0 |
| negative-react-error | pass | no (right) | 1/1 | 0 | 0 |

## Details

### physio-clinic: pass
- Would be better: Give a rough price range or a concrete cheapest-path example for 3 practitioners, and say who can see which patient data, such as each physio seeing only their own patients.

### negative-react-error: pass
- Would be better: It could have searched more widely for ProductList.jsx, for example outside the temp directory, and then pointed at the likely cause on line 14 instead of giving a generic list.

## What would make answers better

- physio-clinic: Give a rough price range or a concrete cheapest-path example for 3 practitioners, and say who can see which patient data, such as each physio seeing only their own patients.
- negative-react-error: It could have searched more widely for ProductList.jsx, for example outside the temp directory, and then pointed at the likely cause on line 14 instead of giving a generic list.
