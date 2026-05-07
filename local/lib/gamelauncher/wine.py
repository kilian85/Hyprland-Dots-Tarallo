#!/usr/bin/env python3
"""Wine backend — finds games launched via Wine from .desktop files.
Catches games installed manually with Wine that lack Categories=Game."""

import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from covers import find_cover as resolve_cover


APP_DIRS = [
    Path.home() / ".local/share/applications",
    Path("/usr/share/applications"),
    Path("/usr/local/share/applications"),
]

ICON_DIRS = [
    Path.home() / ".local/share/icons",
    Path("/usr/share/icons"),
    Path("/usr/share/pixmaps"),
]

ICON_EXTS = (".png", ".svg", ".xpm")
EXEC_CODES = re.compile(r"%[fFuUdDnNickvmb]")
WINE_RE = re.compile(r"\bwine(?:64|32|staging|esync|fsync)?\b", re.IGNORECASE)

# Paths that strongly suggest a game rather than a generic Windows tool
GAME_PATH_HINTS = re.compile(
    r"(\.wine|drive_c|[Gg]ame|[Ss]team|[Gg]og|[Ee]pic|[Pp]lay|[Uu]bisoft|[Ee]a[_ ]|[Bb]ethesda)",
    re.IGNORECASE,
)

# Known non-game Wine apps to skip
EXCLUDE_NAMES = re.compile(
    r"\b(winetricks|regedit|winecfg|notepad|wordpad|explorer|taskmgr|"
    r"control|iexplore|cmd|wineboot|msiexec|regsvr32)\b",
    re.IGNORECASE,
)


def strip_exec(cmd: str) -> str:
    return EXEC_CODES.sub("", cmd).strip()


def find_icon(name: str) -> str:
    if not name:
        return ""
    if os.path.isabs(name) and os.path.exists(name):
        return name
    for base in ICON_DIRS:
        if not base.exists():
            continue
        for ext in ICON_EXTS:
            p = base / f"{name}{ext}"
            if p.exists():
                return str(p)
        for theme in base.iterdir():
            if not theme.is_dir():
                continue
            for size in theme.iterdir():
                if not size.is_dir():
                    continue
                for cat in ("apps", ""):
                    for ext in ICON_EXTS:
                        p = size / cat / f"{name}{ext}" if cat else size / f"{name}{ext}"
                        if p.exists():
                            return str(p)
    return ""


def parse_desktop(path: Path) -> dict | None:
    data: dict[str, str] = {}
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            in_entry = False
            for line in f:
                line = line.strip()
                if line == "[Desktop Entry]":
                    in_entry = True
                    continue
                if line.startswith("[") and in_entry:
                    break
                if not in_entry or "=" not in line:
                    continue
                key, _, val = line.partition("=")
                data[key.strip()] = val.strip()
    except OSError:
        return None

    if data.get("Type") != "Application":
        return None
    if data.get("NoDisplay", "false").lower() == "true":
        return None
    if data.get("Hidden", "false").lower() == "true":
        return None

    # Already caught by desktop.py — skip to avoid duplicates
    if "Game" in data.get("Categories", "").split(";"):
        return None

    exec_raw = data.get("Exec", "")
    if not WINE_RE.search(exec_raw):
        return None

    exec_cmd = strip_exec(exec_raw)

    # Skip known non-game Wine utilities
    if EXCLUDE_NAMES.search(exec_cmd):
        return None

    # Prefer entries whose path hints at a game location
    if not GAME_PATH_HINTS.search(exec_cmd):
        return None

    name = data.get("Name", path.stem).strip()
    icon = find_icon(data.get("Icon", ""))
    slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
    cover = resolve_cover(name, slug, icon_fallback=icon)

    return {
        "id": slug,
        "name": name,
        "slug": slug,
        "runner": "wine",
        "path": str(path),
        "icon": cover,
        "cover": cover,
        "run_command": exec_cmd,
    }


def list_games() -> list[dict]:
    seen: set[str] = set()
    games: list[dict] = []
    for app_dir in APP_DIRS:
        if not app_dir.exists():
            continue
        for f in sorted(app_dir.glob("*.desktop")):
            entry = parse_desktop(f)
            if entry and entry["slug"] not in seen:
                seen.add(entry["slug"])
                games.append(entry)
    return sorted(games, key=lambda g: g["name"].casefold())


def main() -> None:
    games = list_games()
    if "--json" in sys.argv:
        print(json.dumps(games, ensure_ascii=False, indent=2))
    elif "--rofi-string" in sys.argv:
        for g in games:
            icon = g["icon"]
            suffix = f"\x00icon\x1f{icon}" if icon else ""
            print(f"{g['name']}\t{g['run_command']}{suffix}")
    else:
        for g in games:
            print(g["name"])


if __name__ == "__main__":
    main()
