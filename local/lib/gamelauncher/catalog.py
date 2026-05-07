#!/usr/bin/env python3
"""Catalog backend — merges Steam + Lutris + system .desktop games."""

import json
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
BACKENDS = ["steam", "lutris", "desktop", "wine"]


def fetch(backend: str) -> list[dict]:
    script = SCRIPT_DIR / f"{backend}.py"
    try:
        result = subprocess.run(
            [sys.executable, str(script), "--json"],
            capture_output=True, text=True, timeout=10
        )
        return json.loads(result.stdout) if result.stdout.strip() else []
    except Exception as e:
        print(f"catalog: {backend} failed: {e}", file=sys.stderr)
        return []


def list_games() -> list[dict]:
    seen: dict[str, dict] = {}
    for backend in BACKENDS:
        for game in fetch(backend):
            key = game["name"].casefold()
            if key not in seen:
                seen[key] = game
    return sorted(seen.values(), key=lambda g: g["name"].casefold())


def main() -> None:
    games = list_games()
    if "--json" in sys.argv:
        print(json.dumps(games, ensure_ascii=False, indent=2))
    elif "--rofi-string" in sys.argv:
        for g in games:
            icon = g.get("icon") or g.get("cover") or ""
            suffix = f"\x00icon\x1f{icon}" if icon else ""
            print(f"{g['name']}\t{g['run_command']}{suffix}")
    else:
        for g in games:
            print(g["name"])


if __name__ == "__main__":
    main()
