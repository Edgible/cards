# tools

These files are the machinery for any card. A directory under `cards/` is one card. Nothing in here is a card.

## Two kinds of tool

A tool that works on files in this repo runs through `tools/run`, in the image from [Dockerfile](Dockerfile). It may use any package. Add the package to the Dockerfile. Docker is the only thing an author installs.

A tool that checks the machine a card runs on does not run in a container. A container sees its own ports, processes, and files, not the machine's. That tool is one Python file that uses only the standard library, so a card README can fetch it with `curl` and run it with `python3`. `tools/run` refuses to run it.

## run

Runs a tool by its name, the file name without `.py`. Run it from inside the repo. Paths are relative to the directory you run it from.

```bash
tools/run check-cards
tools/run card-image cards/website
```

The first run builds the image, which takes about half a minute. Later runs reuse it. An edit to the Dockerfile builds a new image on the next run. A change to a tool script needs no rebuild, because the repo is mounted into the container. The tool runs as your user, so the files it writes are yours. The pull request workflow runs the same command.

## Dockerfile

The image for `tools/run`: `python:3.12-slim` with the packages the tools import, at pinned versions.

## card.schema.json

The source of truth for `card.yml`. A card matches this schema or it does not. It requires the application fields, allows `none`, `org`, or `api-key`, and requires protocol `https`. It rejects `deviceName`, `deviceId`, and `organization`.

Check a file with `tools/run check-cards`. The command is in the [publish section](../README.md#publish-a-card).

## check-cards.py

Runs that check. With no arguments it checks every `cards/<name>/card.yml`. `metadata.name` must match the directory name. It also checks the names the tools rely on, from the conventions table in the [root README](../README.md#publish-a-card): each app's `<APP>_PORT` in `card.env` with the port from `card.yml`, a Compose file that reads it, `DEVICE` or `<PLACE>_DEVICE` for the places, and a top-level `name:` in each Compose file. Each failure says what to change. The pull request workflow runs this command. A failing check means the card does not match the schema.

```bash
tools/run check-cards
```

## card-image.py

Writes `images/card-light.svg` and `images/card-dark.svg` for a card. The picture lists the apps, ports, auth modes, and places. It draws no caller, no hostname, and no machine. The words come from the card. If a `what` line does not fit the row, the command fails and you shorten that line.

```bash
tools/run card-image cards/website
```

## check-env.py

Checks a fetched card against the machine it is about to run on. Run it after `card.env` is edited and before the containers start. The argument is the card directory. With no `-f`, it checks every `*compose*.yml` in that directory.

```bash
python3 tools/check-env.py cards/website
python3 tools/check-env.py cards/website -f kuma-compose.yml
```

Compose resolves each file with `card.env`, so the ports and names it checks are the ones `docker compose up` would use. It looks for empty required values, host ports already in use, container names already taken, Compose project names used by another file, volumes left by an earlier run, `DEVICE` values that match no device, and Edgible apps with the same name. Each conflict prints a remedy. The report ends with the remedies as lines to paste into a shell. A value that `card.env` says how to generate, such as `# Generate with: openssl rand -hex 16`, is generated there, and a taken port moves to a free one. All `card.env` edits are one `sed`, so `card.env.bak` is the copy from before them. A line that stops or deletes something, such as `docker compose down`, `docker volume rm`, or `edgible app delete`, starts with `#`. `--commands` prints only those lines, for `> fix.sh`. A container, port, project, or volume from the same Compose file is that card already running, and is not a conflict. Exit 0 means no conflicts, 1 means at least one, and 2 means the check could not run.

It needs only `python3` and Docker. It uses `edgible` when that is installed and logged in. A card README fetches this one file with `curl` and runs it, because the card fetch does not include `tools/`.
