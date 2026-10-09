#!/usr/bin/env python3
"""Check a fetched card against the machine it is about to run on.

Run it after card.env is edited and before the containers start:

    python3 check-env.py website
    python3 check-env.py website -f kuma-compose.yml

The argument is the card directory. With no -f, every *compose*.yml in it is
checked. Compose reads card.env and resolves each file, so the ports and names
checked are the ones `docker compose up` would use.

It looks for host ports already taken, container names already taken, Compose
project names already used by other files, leftover volumes, serving devices
that do not match, and Edgible applications with the same name. Each conflict
prints a remedy. A container, project, or volume from the same Compose file is
this card already running, and is not a conflict.

Only the standard library. Exit 0 when nothing conflicts, 1 when something
does, 2 when the check cannot run.
"""

from __future__ import annotations

import argparse
import errno
import json
import re
import shutil
import socket
import subprocess
import sys
from pathlib import Path

REQUIRED_VAR = re.compile(r"\$\{([A-Z][A-Z0-9_]*):\?")
PORT_VAR = re.compile(r"\$\{([A-Z][A-Z0-9_]*)[^}]*\}:\d+")
DEVICE_VAR = re.compile(r"^(?:[A-Z0-9_]+_)?DEVICE$")
TOP_NAME = re.compile(r"^name:\s*\S", re.MULTILINE)
PUBLISHED = re.compile(r"(?:^|:)(\d+)->\d+/(?:tcp|udp)")


class Report:
    def __init__(self) -> None:
        self.conflicts = 0
        self.warnings = 0

    def section(self, title: str) -> None:
        print(f"\n{title}")

    def ok(self, text: str) -> None:
        print(f"  ok        {text}")

    def warn(self, text: str, *remedies: str) -> None:
        self.warnings += 1
        print(f"  warning   {text}")
        for remedy in remedies:
            print(f"            -> {remedy}")

    def conflict(self, text: str, *remedies: str) -> None:
        self.conflicts += 1
        print(f"  conflict  {text}")
        for remedy in remedies:
            print(f"            -> {remedy}")

    def skip(self, text: str) -> None:
        print(f"  skipped   {text}")


def run(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, capture_output=True, text=True)


def read_env(path: Path) -> dict[str, str]:
    env: dict[str, str] = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        env[key.strip()] = value.strip().strip("'\"")
    return env


def read_apps(card_yml: Path) -> list[dict[str, str]]:
    """name and place of each application. card.yml is flat enough to read without pyyaml."""
    apps: list[dict[str, str]] = []
    for line in card_yml.read_text().splitlines():
        match = re.match(r"^\s*-\s+name:\s*(\S+)", line)
        if match:
            apps.append({"name": match.group(1)})
            continue
        match = re.match(r"^\s+place:\s*(\S+)", line)
        if match and apps:
            apps[-1]["place"] = match.group(1)
    return apps


def device_var(place: str, env: dict[str, str]) -> str | None:
    """WEB_DEVICE for place web on a card with several places, DEVICE on a card with one."""
    specific = place.upper().replace("-", "_") + "_DEVICE"
    if specific in env:
        return specific
    if "DEVICE" in env:
        return "DEVICE"
    return None


def port_free(host: str, port: int) -> bool:
    family = socket.AF_INET6 if ":" in host else socket.AF_INET
    with socket.socket(family, socket.SOCK_STREAM) as sock:
        try:
            sock.bind((host, port))
        except OSError as err:
            if err.errno == errno.EADDRINUSE:
                return False
            raise
    return True


def listener(port: int) -> str | None:
    if not shutil.which("lsof"):
        return None
    out = run(["lsof", "+c", "0", "-nP", f"-iTCP:{port}", "-sTCP:LISTEN"]).stdout.splitlines()
    if len(out) < 2:
        return None
    fields = out[1].split()
    return f"{fields[0]} (pid {fields[1]})"


def docker_containers() -> tuple[list[dict], str]:
    """Every container, and the daemon error if `docker ps -a` failed.

    One damaged container makes `docker ps -a` fail for all of them. Listing one
    status at a time still works, so the check falls back to that.
    """
    proc = run(["docker", "ps", "-a", "--format", "{{json .}}"])
    error = ""
    out = proc.stdout
    if proc.returncode != 0:
        error = proc.stderr.strip()
        out = ""
        for status in ("created", "restarting", "running", "removing", "paused", "exited", "dead"):
            out += run(
                ["docker", "ps", "-a", "--filter", f"status={status}", "--format", "{{json .}}"]
            ).stdout
    containers = []
    for line in out.splitlines():
        row = json.loads(line)
        labels = dict(
            item.split("=", 1) for item in row.get("Labels", "").split(",") if "=" in item
        )
        row["Project"] = labels.get("com.docker.compose.project", "")
        row["Service"] = labels.get("com.docker.compose.service", "")
        row["HostPorts"] = {int(p) for p in PUBLISHED.findall(row.get("Ports", ""))}
        containers.append(row)
    return containers, error


def compose_config(compose: Path, env_file: Path) -> tuple[dict | None, str]:
    proc = run(
        [
            "docker", "compose",
            "--env-file", str(env_file),
            "-f", str(compose),
            "config", "--format", "json",
        ]
    )
    if proc.returncode != 0:
        return None, proc.stderr.strip()
    return json.loads(proc.stdout), ""


def next_free_port(start: int, taken: set[int], host: str) -> int:
    port = start + 1
    while port < 65535:
        if port not in taken and port_free(host, port):
            return port
        port += 1
    return start


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("card", type=Path, help="the card directory, such as website")
    parser.add_argument(
        "-f", "--file", action="append", default=[],
        help="a Compose file in the card to check; repeat for more (default: all)",
    )
    parser.add_argument(
        "--env-file", type=Path, help="defaults to card.env in the card directory"
    )
    args = parser.parse_args(argv)

    card = args.card.resolve()
    env_file = (args.env_file or card / "card.env").resolve()
    card_yml = card / "card.yml"
    for path in (card_yml, env_file):
        if not path.is_file():
            print(f"{path} not found", file=sys.stderr)
            return 2
    if args.file:
        files = [(card / name).resolve() for name in args.file]
    else:
        files = sorted(card.glob("*compose*.yml"))
    missing = [str(f) for f in files if not f.is_file()]
    if missing or not files:
        print(f"no Compose file: {', '.join(missing) or card}", file=sys.stderr)
        return 2
    if not shutil.which("docker") or run(["docker", "info"]).returncode != 0:
        print("docker is not running on this machine", file=sys.stderr)
        return 2

    env = read_env(env_file)
    apps = read_apps(card_yml)
    report = Report()
    print(f"card {card.name}, settings {env_file}")

    # Resolve every file first. A missing value stops the rest for that file.
    report.section("card.env")
    resolved: list[tuple[Path, dict]] = []
    for compose in files:
        # Compose stops at the first empty value, so list every required one here.
        required = dict.fromkeys(REQUIRED_VAR.findall(compose.read_text()))
        empty = [var for var in required if not env.get(var)]
        if empty:
            report.conflict(
                f"{compose.name} needs a value for {', '.join(empty)}",
                f"fill each in {env_file.name}; its comment says how to make one",
            )
            continue
        config, error = compose_config(compose, env_file)
        if config is None:
            last = error.splitlines()[-1] if error else "docker compose config failed"
            report.conflict(f"{compose.name}: {last}", f"fix that in {env_file.name} or {compose.name}")
            continue
        resolved.append((compose, config))
        report.ok(f"{compose.name} resolves")
    for key, value in env.items():
        if DEVICE_VAR.match(key) and not value:
            report.conflict(
                f"{key} is empty",
                f"set {key} to a name that `edgible device list` prints",
            )

    containers, ps_error = docker_containers()
    if ps_error:
        report.section("Docker")
        damaged = re.search(r"container ([0-9a-f]{12})", ps_error)
        report.warn(
            f"`docker ps -a` fails: {ps_error}",
            "the check listed containers one status at a time instead",
            f"remove the damaged container: docker rm -f {damaged.group(1)}"
            if damaged
            else "restart Docker, then run this again",
        )
    projects = {
        p["Name"]: p
        for p in json.loads(run(["docker", "compose", "ls", "-a", "--format", "json"]).stdout or "[]")
    }
    volumes = set(run(["docker", "volume", "ls", "-q"]).stdout.split())

    # Compose project names.
    report.section("Compose projects")
    own_projects: set[str] = set()
    for compose, config in resolved:
        project = config["name"]
        if not TOP_NAME.search(compose.read_text()):
            report.warn(
                f"{compose.name} has no top-level name:, so this check assumes the project "
                f"is named after its directory ({project})",
                f"add `name: <project>` as the first line of {compose.name}, using the "
                "--project-name its README passes, or the directory name if it passes none",
            )
        existing = projects.get(project)
        if existing is None:
            own_projects.add(project)
            report.ok(f"{project} is free")
            continue
        config_files = [Path(p).resolve() for p in existing["ConfigFiles"].split(",") if p]
        if compose.resolve() in config_files:
            own_projects.add(project)
            report.ok(f"{project} is this file, already {existing['Status']}")
            continue
        others = ", ".join(str(p) for p in config_files)
        if any(p.name == compose.name and p.parent.name == card.name for p in config_files):
            report.conflict(
                f"{project} is running from another copy of this card: {others}",
                f"start it from that directory instead, so it keeps its data",
                f"or stop that copy first: docker compose -p {project} down (volumes stay)",
            )
        else:
            report.conflict(
                f"{project} is already used by {others}",
                f"change `name: {project}` in {compose.name} to a name that is free",
                "Compose would otherwise replace that project's containers",
            )

    # Container names.
    report.section("Container names")
    by_name = {c["Names"]: c for c in containers}
    found = False
    for compose, config in resolved:
        project = config["name"]
        for service, spec in config.get("services", {}).items():
            name = spec.get("container_name")
            if not name:
                continue
            found = True
            other = by_name.get(name)
            if other is None:
                report.ok(f"{name} is free")
            elif other["Project"] == project and project in own_projects:
                report.ok(f"{name} is this card, already {other['State']}")
            else:
                owner = f"project {other['Project']}" if other["Project"] else "no Compose project"
                rename = f"or change container_name for {service} in {compose.name}"
                if other["Project"] in projects:
                    first = f"stop that project first: docker compose -p {other['Project']} down (volumes stay)"
                elif other["State"] == "running":
                    first = f"stop and remove it if you no longer need it: docker rm -f {name}"
                else:
                    first = f"it is stopped; remove it if it is left over: docker rm {name}"
                report.conflict(
                    f"{name} is taken by a container from {owner} ({other['State']})",
                    first,
                    rename,
                )
    if not found:
        report.ok("no fixed container names; Compose prefixes them with the project")

    # Host ports.
    report.section("Host ports")
    wanted: dict[int, list[str]] = {}
    for compose, config in resolved:
        project = config["name"]
        port_vars = PORT_VAR.findall(compose.read_text())
        for service, spec in config.get("services", {}).items():
            for mapping in spec.get("ports", []):
                if not mapping.get("published"):
                    continue
                port = int(mapping["published"])
                host = mapping.get("host_ip") or "0.0.0.0"
                var = next((v for v in port_vars if env.get(v) == str(port)), None)
                wanted.setdefault(port, []).append(f"{project}/{service}")
                setting = f"{var}={port}" if var else f"port {port}"
                taken = set(wanted) | {p for c in containers for p in c["HostPorts"]}
                remedy_port = next_free_port(port, taken, host)
                change = (
                    f"set {var}={remedy_port} in {env_file.name}"
                    if var
                    else f"change the host port for {service} in {compose.name}"
                )
                users = [c for c in containers if port in c["HostPorts"]]
                ours = [c for c in users if c["Project"] == project and project in own_projects]
                theirs = [c for c in users if c not in ours]
                if theirs:
                    other = theirs[0]
                    owner = f" in project {other['Project']}" if other["Project"] else ""
                    report.conflict(
                        f"{setting} ({service}) is published by container {other['Names']}{owner}",
                        change,
                        f"or stop that container: docker stop {other['Names']}",
                    )
                elif ours:
                    report.ok(f"{setting} ({service}) is this card, already published")
                elif not port_free(host, port):
                    who = listener(port)
                    report.conflict(
                        f"{setting} ({service}) is in use on {host}"
                        + (f" by {who}" if who else ""),
                        change,
                        "or stop the program that listens there",
                    )
                else:
                    stale = [
                        c for c in containers
                        if c["Project"] == project and project in own_projects
                        and c["Service"] == service and c["State"] == "running"
                    ]
                    if stale:
                        report.warn(
                            f"{setting} ({service}) is free, but container {stale[0]['Names']} "
                            "is running without it; the published app cannot reach it",
                            f"restart it: docker restart {stale[0]['Names']}",
                        )
                    else:
                        report.ok(f"{setting} ({service}) is free")
    for port, users in wanted.items():
        if len(users) > 1:
            report.conflict(
                f"port {port} is used twice in this card: {', '.join(users)}",
                "give each one its own port in card.env",
            )

    # Volumes left by an earlier run. Postgres keeps the old password in them.
    report.section("Volumes")
    found = False
    for compose, config in resolved:
        project = config["name"]
        running = project in projects and project in own_projects
        for volume in config.get("volumes", {}).values():
            name = volume.get("name")
            if not name or volume.get("external"):
                continue
            found = True
            if name not in volumes:
                report.ok(f"{name} is new")
            elif running:
                report.ok(f"{name} is this card's data")
            elif project in projects:
                report.warn(
                    f"{name} belongs to project {project}, which runs from "
                    f"{projects[project]['ConfigFiles']}; starting here would share that data",
                    "fix the Compose project conflict above first",
                )
            else:
                report.warn(
                    f"{name} is left from an earlier run; it is reused as it is, "
                    "including any database password it was made with",
                    "keep it if you want that data",
                    f"to start empty, delete it and its data: docker volume rm {name}",
                )
    if not found:
        report.ok("no named volumes")

    # Edgible: devices and application names.
    report.section("Edgible")
    if not shutil.which("edgible"):
        report.skip("edgible is not installed; the device and app name checks need it")
    else:
        devices_out = run(["edgible", "device", "list", "--json"])
        apps_out = run(["edgible", "app", "list", "--json"])
        if devices_out.returncode != 0 or apps_out.returncode != 0:
            report.skip("edgible could not list devices and apps; run `edgible login`")
        else:
            devices = json.loads(devices_out.stdout)
            existing_apps = {a["name"]: a for a in json.loads(apps_out.stdout)}
            for key, value in env.items():
                if not DEVICE_VAR.match(key) or not value:
                    continue
                matches = [d for d in devices if d["name"] == value]
                if len(matches) == 1:
                    report.ok(f"{key}={value} is device {matches[0]['id']} ({matches[0]['status']})")
                elif not matches:
                    names = ", ".join(sorted(d["name"] for d in devices)) or "none"
                    report.conflict(
                        f"{key}={value} matches no device",
                        f"use one of: {names}",
                    )
                else:
                    report.conflict(
                        f"{key}={value} matches {len(matches)} devices",
                        "rename one with `edgible device` so each name is unique",
                    )
            for app in apps:
                other = existing_apps.get(app["name"])
                if other is None:
                    report.ok(f"app {app['name']} is free")
                    continue
                key = device_var(app.get("place", ""), env)
                device = env.get(key, "") if key else ""
                on = ", ".join(d["name"] for d in other.get("devices", [])) or "no device"
                if device and device in on.split(", "):
                    report.warn(
                        f"app {app['name']} already exists on {device} ({other['status']}, "
                        f"port {other.get('port')})",
                        "if this card published it before, skip it in the Publish step",
                        f"to publish it again: edgible app delete {app['name']}",
                    )
                else:
                    report.conflict(
                        f"app {app['name']} already exists on {on} ({other['status']})",
                        f"if it is unused: edgible app delete {app['name']}",
                        f"or publish this one under another name, such as --name {card.name}-{app['name']}",
                    )

    print()
    if report.conflicts:
        print(f"{report.conflicts} conflict(s), {report.warnings} warning(s). "
              "Fix the conflicts, then run this again.")
        return 1
    print(f"no conflicts, {report.warnings} warning(s). Start the containers.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
