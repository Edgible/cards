#!/usr/bin/env python3
"""Check card.yml files against tools/card.schema.json.

With no arguments, checks every cards/<name>/card.yml.
With arguments, checks those files.
metadata.name must match the directory name.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator
from jsonschema.exceptions import ValidationError

ROOT = Path(__file__).resolve().parent.parent
SCHEMA_PATH = ROOT / "tools" / "card.schema.json"


def card_paths(argv: list[str]) -> list[Path]:
    if argv:
        return [Path(arg).resolve() for arg in argv]
    found = sorted((ROOT / "cards").glob("*/card.yml"))
    if not found:
        sys.exit("no cards found")
    return found


def main(argv: list[str]) -> int:
    schema = json.loads(SCHEMA_PATH.read_text())
    validator = Draft202012Validator(
        schema, format_checker=Draft202012Validator.FORMAT_CHECKER
    )
    failed = False
    for path in card_paths(argv):
        try:
            card = yaml.safe_load(path.read_text())
            name = card["metadata"]["name"]
            if name != path.parent.name:
                raise SystemExit(
                    f"{path}: metadata.name is {name}, directory is {path.parent.name}"
                )
            validator.validate(card)
        except (OSError, KeyError, TypeError, ValidationError, yaml.YAMLError) as exc:
            print(f"{path}: {exc}", file=sys.stderr)
            failed = True
            continue
        print(f"ok {path}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
