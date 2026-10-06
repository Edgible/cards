#!/usr/bin/env python3
"""Write a deployable stack file from a card.

Stand-in for a later `edgible stack export --card`. The card stays free of
device names and the organization id. This script fills those in and prints
one `kind: Application` document per app, which `edgible stack deploy` accepts.

    python3 card-to-stack.py website-card.yml --device minipc > website.stack.yml
    python3 card-to-stack.py website-card.yml --device web=minipc --device monitor=otherbox

tools/card.schema.json in this repo is the source of truth for the file.
This script checks only the fields it copies into a stack file.

The organization id is `edgible config get organizationId`, unless you pass
`--org`. The workload is `pre-existing`: the process must already be listening
on the named device. This script does not start containers.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


AUTH = {
    "none": "none",
    "org": "edgible-login",
    "api-key": "api-key",
}


def parse_card(text: str) -> list[dict[str, str]]:
    apps: list[dict[str, str]] = []
    current: dict[str, str] | None = None
    in_apps = False
    for raw in text.splitlines():
        if not raw.strip() or raw.strip().startswith("#"):
            continue
        stripped = raw.strip()
        if stripped == "applications:":
            in_apps = True
            continue
        if not in_apps:
            continue
        if stripped.startswith("- "):
            if current:
                apps.append(current)
            current = {}
            stripped = stripped[2:].strip()
        if current is None or ":" not in stripped:
            continue
        key, value = stripped.split(":", 1)
        key = key.strip()
        value = value.strip()
        current[key] = value
    if current:
        apps.append(current)
    if not apps:
        raise SystemExit("card has no applications")
    return apps


def devices_from(flags: list[str], apps: list[dict[str, str]]) -> dict[str, str]:
    """One bare name applies to every app. place=device or app=device overrides."""
    names = [app["name"] for app in apps]
    place_of = {app["name"]: app.get("place", "") for app in apps}
    places = {place for place in place_of.values() if place}
    assigned: dict[str, str] = {}
    default: str | None = None
    for flag in flags:
        if "=" in flag:
            key, device = flag.split("=", 1)
            if not key or not device:
                raise SystemExit(f"bad --device {flag!r}, use place=device or app=device")
            assigned[key] = device
        else:
            if default is not None:
                raise SystemExit("pass one device name, or place=device pairs")
            default = flag
    out: dict[str, str] = {}
    missing = []
    for name in names:
        place = place_of[name]
        if name in assigned:
            device = assigned[name]
        elif place in assigned:
            device = assigned[place]
        else:
            device = default
        if not device:
            missing.append(name)
        else:
            out[name] = device
    if missing:
        raise SystemExit(
            "no device for: "
            + ", ".join(missing)
            + ". Pass --device NAME, --device place=NAME, or --device app=NAME"
        )
    known = set(names) | places
    unknown = sorted(set(assigned) - known)
    if unknown:
        raise SystemExit("card has no app or place named: " + ", ".join(unknown))
    return out


def organization(explicit: str | None) -> str:
    if explicit:
        return explicit
    try:
        out = subprocess.run(
            ["edgible", "config", "get", "organizationId"],
            check=True,
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        raise SystemExit("pass --org, or log in so `edgible config get organizationId` prints one") from exc
    org = out.stdout.strip()
    if not org:
        raise SystemExit("pass --org, or log in so `edgible config get organizationId` prints one")
    return org


def auth_modes(raw: str) -> list[str]:
    inner = raw.strip()
    if inner.startswith("[") and inner.endswith("]"):
        inner = inner[1:-1]
    modes = [part.strip() for part in inner.split(",") if part.strip()]
    if not modes:
        raise SystemExit(f"authModes is empty: {raw!r}")
    mapped = []
    for mode in modes:
        if mode not in AUTH:
            raise SystemExit(f"unknown auth mode {mode!r}")
        mapped.append(AUTH[mode])
    return mapped


def quote(value: str) -> str:
    return json.dumps(value)


def render(apps: list[dict[str, str]], device_of: dict[str, str], org: str) -> str:
    docs = []
    for app in apps:
        name = app.get("name", "")
        if not name:
            raise SystemExit("an application is missing name")
        for banned in ("deviceName", "hostnames", "organization"):
            if banned in app:
                raise SystemExit(f"{name} still has {banned}; a card leaves that out")
        if app.get("subtype", "existing") not in ("existing", ""):
            raise SystemExit(f"{name} subtype must be existing")
        try:
            port = int(app["port"])
        except (KeyError, ValueError) as exc:
            raise SystemExit(f"{name} needs an integer port") from exc
        modes = auth_modes(app.get("authModes", ""))
        mode_list = ", ".join(modes)
        docs.append(
            "\n".join(
                [
                    "apiVersion: v3",
                    "kind: Application",
                    "metadata:",
                    f"  name: {quote(name)}",
                    f"  organization: {quote(org)}",
                    "spec:",
                    "  placement:",
                    "    strategy: serving-device",
                    "    deviceSelector:",
                    f"      deviceName: {quote(device_of[name])}",
                    "  workloads:",
                    f"    - name: {quote(name)}",
                    "      type: pre-existing",
                    f"      hostPort: {port}",
                    "      ports:",
                    "        - name: http",
                    f"          containerPort: {port}",
                    "  access:",
                    "    - name: https",
                    "      type: https",
                    "      target:",
                    f"        workload: {quote(name)}",
                    "        port: http",
                    "      policies:",
                    "        auth:",
                    f"          modes: [{mode_list}]",
                ]
            )
        )
    return "\n---\n".join(docs) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Write a stack file from a card")
    parser.add_argument("card", type=Path)
    parser.add_argument(
        "--device",
        action="append",
        required=True,
        help="one device for every app, or place=device, or app=device",
    )
    parser.add_argument("--org", help="organization id (default: edgible config get organizationId)")
    parser.add_argument("-o", "--output", help="write here instead of stdout")
    args = parser.parse_args()
    apps = parse_card(args.card.read_text())
    text = render(apps, devices_from(args.device, apps), organization(args.org))
    if args.output:
        Path(args.output).write_text(text)
    else:
        sys.stdout.write(text)


if __name__ == "__main__":
    main()
