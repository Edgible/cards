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

Runs that check. With no arguments it checks every `cards/<name>/card.yml`. `metadata.name` must match the directory name. The pull request workflow runs this command. A failing check means the card does not match the schema.

```bash
tools/run check-cards
```

## card-image.py

Writes `images/card-light.svg` and `images/card-dark.svg` for a card. The picture lists the apps, ports, auth modes, and places. It draws no caller, no hostname, and no machine. The words come from the card. If a `what` line does not fit the row, the command fails and you shorten that line.

```bash
tools/run card-image cards/website
```
