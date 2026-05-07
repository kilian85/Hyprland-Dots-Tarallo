#!/usr/bin/env python3
"""Desktop backend — reads .desktop files with Categories=Game from XDG app dirs.
Covers games installed via AUR/pacman/flatpak/appimage that ship a .desktop file."""

import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from covers import find_cover as resolve_cover


APP_DIRS = [
    Path("/usr/share/applications"),
    Path("/usr/local/share/applications"),
    Path.home() / ".local/share/applications",
    Path("/var/lib/flatpak/exports/share/applications"),
    Path.home() / ".local/share/flatpak/exports/share/applications",
]

ICON_DIRS = [
    Path.home() / ".local/share/icons",
    Path("/usr/share/icons"),
    Path("/usr/share/pixmaps"),
]

ICON_EXTS = (".png", ".svg", ".xpm")
EXEC_CODES = re.compile(r"%[fFuUdDnNickvmb]")


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
        # Flat pixmaps dir
        for ext in ICON_EXTS:
            p = base / f"{name}{ext}"
            if p.exists():
                return str(p)
        # Theme subdirs: walk two levels (theme/size/category)
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
    if "Game" not in data.get("Categories", "").split(";"):
        return None
    if data.get("NoDisplay", "false").lower() == "true":
        return None
    if data.get("Hidden", "false").lower() == "true":
        return None

    name = data.get("Name", "").strip()
    exec_cmd = strip_exec(data.get("Exec", ""))
    if not name or not exec_cmd:
        return None

    icon = find_icon(data.get("Icon", ""))
    slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
    cover = resolve_cover(name, slug, icon_fallback=icon)

    return {
        "id": slug,
        "name": name,
        "slug": slug,
        "runner": "desktop",
        "path": str(path),
        "icon": cover,
        "cover": cover,
        "run_command": exec_cmd,
    }


def _excluded_names() -> set[str]:
    exclude_file = Path.home() / ".config/gamelauncher/exclude"
    if not exclude_file.exists():
        return set()
    return {
        line.strip().casefold()
        for line in exclude_file.read_text().splitlines()
        if line.strip() and not line.startswith("#")
    }


def list_games() -> list[dict]:
    excluded = _excluded_names()
    seen: set[str] = set()
    games: list[dict] = []
    for app_dir in APP_DIRS:
        if not app_dir.exists():
            continue
        for f in sorted(app_dir.glob("*.desktop")):
            entry = parse_desktop(f)
            if entry and entry["slug"] not in seen:
                if entry["name"].casefold() in excluded:
                    continue
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
