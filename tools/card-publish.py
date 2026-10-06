#!/usr/bin/env python3
"""Publish the apps on a card with edgible app create existing.

The card stays free of device names and the organization id. You pass the
device name for each place. One bare name covers every app. The organization
comes from the logged-in CLI. The script looks up each name in
`edgible device list` and runs create once per app.

    python3 card-publish.py assistant-card.yml --device minipc
    python3 card-publish.py website-card.yml --device web=minipc --device monitor=otherbox

The process must already be listening on that port. This script does not
fetch Compose URLs and does not start containers.

--dry-run prints the commands and does not call the CLI.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


AUTH = ("none", "org", "api-key")


def parse_card(text: str) -> list[dict[str, str]]:
    apps: list[dict[str, str]] = []
    current: dict[str, str] | None = None
    in_apps = False
    skip_deeper_than: int | None = None
    for raw in text.splitlines():
        if not raw.strip() or raw.strip().startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        if skip_deeper_than is not None:
            if indent > skip_deeper_than:
                continue
            skip_deeper_than = None
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
        if key == "resources" and not value:
            skip_deeper_than = indent
            continue
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
    known = set(names) | places
    unknown = sorted(set(assigned) - known)
    if unknown:
        raise SystemExit("card has no app or place named: " + ", ".join(unknown))
    if missing:
        raise SystemExit(
            "no device for: "
            + ", ".join(missing)
            + ". Pass --device NAME, --device place=NAME, or --device app=NAME"
        )
    return out


def auth_modes(raw: str) -> str:
    inner = raw.strip()
    if inner.startswith("[") and inner.endswith("]"):
        inner = inner[1:-1]
    modes = [part.strip() for part in inner.split(",") if part.strip()]
    if not modes:
        raise SystemExit(f"authModes is empty: {raw!r}")
    for mode in modes:
        if mode not in AUTH:
            raise SystemExit(f"unknown auth mode {mode!r}")
    return ",".join(modes)


def checked_apps(apps: list[dict[str, str]]) -> list[dict[str, str]]:
    for app in apps:
        name = app.get("name", "")
        if not name:
            raise SystemExit("an application is missing name")
        for banned in ("deviceName", "deviceId", "hostnames", "organization"):
            if banned in app:
                raise SystemExit(f"{name} still has {banned}; a card leaves that out")
        if app.get("subtype", "existing") not in ("existing", ""):
            raise SystemExit(f"{name} subtype must be existing")
        try:
            int(app["port"])
        except (KeyError, ValueError) as exc:
            raise SystemExit(f"{name} needs an integer port") from exc
        auth_modes(app.get("authModes", ""))
    return apps


def device_ids(names: set[str]) -> dict[str, str]:
    try:
        out = subprocess.run(
            ["edgible", "device", "list", "--json"],
            check=True,
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        detail = exc.stderr.strip() if isinstance(exc, subprocess.CalledProcessError) else str(exc)
        raise SystemExit("edgible device list --json failed: " + detail) from exc
    try:
        devices = json.loads(out.stdout)
    except json.JSONDecodeError as exc:
        raise SystemExit("edgible device list --json did not print a device list") from exc
    if not isinstance(devices, list):
        raise SystemExit("edgible device list --json did not print a device list")
    by_name: dict[str, str] = {}
    for device in devices:
        if not isinstance(device, dict):
            continue
        name = device.get("name")
        ident = device.get("id")
        if not name or not ident:
            continue
        if name in by_name:
            raise SystemExit(f"more than one device is named {name}")
        by_name[name] = ident
    missing = sorted(names - set(by_name))
    if missing:
        raise SystemExit("no device named: " + ", ".join(missing))
    return {name: by_name[name] for name in names}


def command(app: dict[str, str], device_id: str) -> list[str]:
    argv = [
        "edgible",
        "app",
        "create",
        "existing",
        "--non-interactive",
        "--name",
        app["name"],
        "--port",
        str(int(app["port"])),
        "--protocol",
        app.get("protocol") or "https",
        "--auth-modes",
        auth_modes(app.get("authModes", "")),
        "--device-id",
        device_id,
    ]
    what = app.get("what", "")
    if what:
        argv.extend(["--description", what])
    return argv


def main() -> None:
    parser = argparse.ArgumentParser(description="Publish the apps on a card")
    parser.add_argument("card", type=Path)
    parser.add_argument(
        "--device",
        action="append",
        required=True,
        help="one device name for every app, or place=name, or app=name",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="print the create commands and do not call the CLI",
    )
    args = parser.parse_args()
    apps = checked_apps(parse_card(args.card.read_text()))
    device_of = devices_from(args.device, apps)
    ids = {} if args.dry_run else device_ids(set(device_of.values()))
    for app in apps:
        device_name = device_of[app["name"]]
        if args.dry_run:
            print(f"# {app['name']} on {device_name}")
            print(" ".join(command(app, "<" + device_name + ">")))
            continue
        subprocess.run(command(app, ids[device_name]), check=True)


if __name__ == "__main__":
    main()
