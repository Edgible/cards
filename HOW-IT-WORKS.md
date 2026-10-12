# How it works

This page is the whole system in one place: the pieces, the life of a card, and every automated job, with where it runs and where its results go. Everything here is public, except the logins the test runner uses.

## The pieces

| Piece | Where | What it is |
| --- | --- | --- |
| Cards | [Edgible/cards](https://github.com/Edgible/cards), this repo | Self-hosted setups anyone can run. **App cards** (`metadata.type: app`) are one app each, always tested. **Pattern cards** (`metadata.type: pattern`) wire several apps together, built from app cards. |
| The format and tools | [Edgible/card-kit](https://github.com/Edgible/card-kit) | The card format (`card.schema.json`), and the tools that check, test, and document a card: `check-cards`, `check-env`, `test-card`, `test-cards`, `card-readme`, `card-image`, `check-map`. |
| The agent skill | [card-kit/skills/edgible-cards](https://github.com/Edgible/card-kit/tree/main/skills/edgible-cards) | Teaches an AI agent to go from a person's need to a running, published card, look after it, and contribute back. Works in Claude Code, Claude's apps, and other agents that read the Agent Skills format. |
| The needs map | [needs-map.yaml](https://github.com/Edgible/card-kit/blob/main/skills/edgible-cards/needs-map.yaml), beside the skill | What people say they need, mapped to categories, the questions that decide the answer, how to publish safely, and the cards for it. Built on [awesome-selfhosted](https://awesome-selfhosted.net)'s categories, plus categories Edgible adds where that list has none yet, mostly AI tools. |
| The skill's tests | [card-kit/skills/edgible-cards/evals](https://github.com/Edgible/card-kit/tree/main/skills/edgible-cards/evals) | Prompts the skill should and should not answer, held-out real prompts that answers are scored against, and the tool that measures triggering. |
| MCP | The [mcp-bridge](mcp-bridge) app card | Publishes any stdio MCP server over Streamable HTTP, so AI assistants reach it from anywhere. An Edgible MCP server for finding cards is built on it. |

Edgible itself is not here. Cards are free and portable; Edgible is the platform that publishes them: hostnames and TLS, auth modes, TCP and UDP, the device agent, and teams.

## The life of a card

1. **Someone needs it.** A person describes a need to an AI assistant with the skill, or opens a request issue. When no card fits, the skill shortlists apps from awesome-selfhosted and other current sources, and offers to build one.
2. **It is built and tested.** The author, often with an agent, writes the card from the closest existing one, and runs `test-card` on their own Edgible serving device. That runs the whole lifecycle (check the machine, start, publish, verify each hostname, the card's own checks, tear down) and writes `test.yml`.
3. **It is checked and reviewed.** The pull request runs `check-cards --fresh`: the schema, the conventions, the app-card rules, and that `test.yml` matches the files. A maintainer reviews what a test cannot judge, from the checklist in the pull request template, and runs `test-card` on an Edgible device before merging. The merge is the publish.
4. **It keeps being tested.** Every night, the regression retests each card that changed, and every card when Edgible releases a new version. Its badge in the README shows the result and the Edgible version. A failure opens an issue.
5. **It is used, and it improves.** People run it from its README or through the skill. A problem found in use becomes a fix and a pull request, by the same path.
6. **It may be promoted.** An app card that passes for weeks, and that tags show many people keep running, can be packaged as a managed Edgible template. The card stays the source.

## The automated jobs

| Job | Trigger | Runs on | What it does | Results go to |
| --- | --- | --- | --- | --- |
| **cards** ([cards.yml](.github/workflows/cards.yml)) | Every pull request and push to `main` here | GitHub's own runners | `check-cards --fresh` on every card | The pull request's check |
| **kit** ([card-kit's kit.yml](https://github.com/Edgible/card-kit/blob/main/.github/workflows/kit.yml)) | Every pull request and push to card-kit | GitHub's own runners | `check-cards` on every card here, so a change to the tools cannot break a card; `check-map` on the needs map | The pull request's check |
| **regression** ([regression.yml](.github/workflows/regression.yml)) | Nightly, and by hand with `force` or `only` | A self-hosted runner: a machine with Docker, the `edgible` CLI signed in, and a serving device | `test-cards --spread 7`: tests a new or changed card that night, and spreads every other test (a new Edgible version, or a week without one) over the week, about a seventh of the cards a night, so each card is also retested weekly. Each test is the full lifecycle on a real device | The [`test-status` branch](https://github.com/Edgible/cards/tree/test-status) (`status.json` and one badge file per card), and an issue for each failure |
| **grow** ([grow.yml](.github/workflows/grow.yml)) | Nightly, and by hand with an app name; skipped while 3 agent-made pull requests await review | The self-hosted runner, with the `claude` CLI signed in | Picks the first gap in the needs map (`pick-app`), has an agent with the skill write one app card for the best-fitting app, checks it with `check-cards --untrusted` (nothing that reaches outside the card), and tests it with `test-card`, with up to three fix attempts. The agent has its own home folder and a short list of commands, and no GitHub or Edgible login | A pull request labelled `agent-card` for a person to review, or an `app-request` issue saying how far it got. Nothing is merged automatically. Each run also opens a card-kit pull request adding merged agent cards to their category in the needs map |
| **daily-report** ([daily-report.yml](.github/workflows/daily-report.yml)) | Daily at 21:00 UTC, and by hand | The self-hosted runner | Gathers what the night's jobs did from GitHub (`.github/scripts/daily_report.py`), lists the actions for a person first, and adds a two-sentence summary from a small model | The pinned **Daily report** issue: its text is the latest report, and each day's is a comment that mentions the person in `REPORT_NOTIFY`, so GitHub emails them. Each report is also kept on the `reports` branch. A watchdog on GitHub's own runners (`daily-report-watchdog.yml`, 23:30 UTC) comments when a morning has no report, such as when the Mac was off |
| **runner-check** ([runner-check.yml](.github/workflows/runner-check.yml)) | By hand | The self-hosted runner | Proves the runner can reach Docker and Edgible | The run's log |
| **skill-evals** ([skill-evals.yml](.github/workflows/skill-evals.yml)) | Nightly, and by hand | The self-hosted runner, with the `claude` CLI signed in | Tonight's share of the skill's held-out prompts (each runs once a week, about N/7 a night), answered in read-only sessions with the skill and judged by a second session | The [`eval-results` branch](https://github.com/Edgible/cards/tree/eval-results), and the **Skill eval report** issue, combining the last seven nights |

Lifecycle tests, evals, and the grow job never run from a pull request.

The jobs that use Claude run early in the night (evals at 13:00 UTC, grow at 14:00 UTC), so the usage window each opens on the runner's subscription has closed before the working day. Grow skips a night when that night's evals stopped early, such as at the usage limit; the judge and grow's agent use a smaller model, and the answering sessions the default one. A pull request only gets the checks that need no Edgible account, on GitHub's runners. Everything that publishes apps runs from `main`, by schedule or by a maintainer's hand.

## Public and private

Everything about cards is public: the cards, the tools, the skill, its tests, the workflows, the test results, and the eval reports. Public results build trust, let anyone see what works today, and give people and AI assistants something to find and cite. They also mean a runner can be replaced at any time: all the state lives in the repos, not on the machine.

What stays private is only what would let someone act as Edgible:

- the runner's Edgible sign-in and its machine;
- tokens, API keys, and passwords, which never appear in a card, a test result, or a log;
- device names, hostnames, and organization ids, which `check-cards` refuses in `test.yml`;
- a small reserve of held-out eval prompts, kept unpublished so the scores can tell whether a model has learned the public ones.

### The self-hosted runner and pull requests

A runner that can publish apps must never run code from a pull request, because a pull request from a fork can change a workflow. So:

- the regression and eval workflows trigger only on `schedule` and `workflow_dispatch`, never on `pull_request`;
- workflow runs from outside contributors need a maintainer's approval (the repo's Actions setting for fork pull requests);
- the runner is registered to this repo only, and does nothing but these jobs.

## Where things are going

- **The regression moved here.** Until 2026-10-11 it ran from a private workflow, with its status kept privately. It now runs from [regression.yml](.github/workflows/regression.yml) in this repo and publishes to `test-status` directly. The serving device it publishes on is the repository variable `TEST_DEVICE`, so no device name is in the file.
- **Pattern cards include app cards** with Compose `include:` rather than copying their services, so a fix to an app card reaches every pattern built on it.
- **The skill eval loop grows:** generated scenarios each week, and a scan for emerging needs (the MCP Registry, GitHub, self-hosting forums) that proposes needs-map entries as pull requests.
- **Platform primitives** the cards keep needing, such as tags for counting deployments, sign-in for MCP clients, and backup and restore, are tracked by Edgible.
