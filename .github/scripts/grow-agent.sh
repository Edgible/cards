#!/usr/bin/env bash
# One Claude Code session for the grow job's agent, with the edgible-cards skill and a short
# list of commands: card-kit's tools and Docker image lookups. No shell beyond that, and no
# GitHub or Edgible login. Run it from the job's folder, which holds card-kit/ and work/cards/:
#
#   .github/scripts/grow-agent.sh "<prompt>"     (the copy in cards/, which the job checked out)
#
# The session's output is appended to agent.log, and its last 3000 characters are printed.
set -euo pipefail
prompt=$1
mkdir -p agent-home/.claude/skills
rm -rf agent-home/.claude/skills/edgible-cards
cp -R card-kit/skills/edgible-cards agent-home/.claude/skills/
[ -e work/card-kit ] || ln -s "$PWD/card-kit" work/card-kit
docker_host=$(docker context inspect --format '{{.Endpoints.docker.Host}}')
( cd work/cards && env -i PATH="$PATH" HOME="$PWD/../../agent-home" LANG=en_US.UTF-8 \
    CLAUDE_CODE_OAUTH_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN" DOCKER_HOST="$docker_host" \
    GH_TOKEN=disabled GITHUB_TOKEN=disabled GIT_CONFIG_NOSYSTEM=1 \
    claude -p "$prompt" --model sonnet --max-turns 80 \
      --allowedTools Read Write Edit Glob Grep WebFetch Skill \
        "Bash(../card-kit/run:*)" "Bash(docker manifest inspect:*)" "Bash(docker buildx imagetools inspect:*)" \
      --disallowedTools "Bash(gh:*)" "Bash(git:*)" "Bash(curl:*)" "Bash(docker run:*)" "Bash(docker compose:*)" ) \
  >> agent.log 2>&1 || true
tail -c 3000 agent.log
