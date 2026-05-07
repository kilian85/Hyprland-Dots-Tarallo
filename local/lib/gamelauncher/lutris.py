#!/usr/bin/env python3
"""Lutris backend — reads installed games from the Lutris SQLite database."""

import json
import sqlite3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from covers import find_cover as resolve_cover


DB_PATHS = [
    Path.home() / ".local/share/lutris/pga.db",
    Path.home() / ".local/share/lutris/lutris.db",
    Path.home() / ".var/app/net.lutris.Lutris/data/lutris/pga.db",
    Path.home() / ".var/app/net.lutris.Lutris/data/lutris/lutris.db",
]

COVERART = Path.home() / ".local/share/lutris/coverart"
ICONS = Path.home() / ".local/share/icons/hicolor/128x128/apps"


def find_db() -> Path | None:
    candidates = [p for p in DB_PATHS if p.exists()]
    return max(candidates, key=lambda p: p.stat().st_mtime) if candidates else None


def find_icon(slug: str) -> str:
    for ext in (".jpg", ".png", ".jpeg"):
        p = COVERART / f"{slug}{ext}"
        if p.exists():
            return str(p)
    p = ICONS / f"lutris_{slug}.png"
    return str(p) if p.exists() else ""


def list_games() -> list[dict]:
    db = find_db()
    if not db:
        return []
    games: list[dict] = []
    try:
        with sqlite3.connect(db) as conn:
            conn.row_factory = sqlite3.Row
            rows = conn.execute(
                "SELECT id, name, slug, runner FROM games WHERE installed = 1 ORDER BY name COLLATE NOCASE"
            ).fetchall()
        for row in rows:
            slug = row["slug"] or ""
            name = row["name"]
            icon = find_icon(slug)
            cover = resolve_cover(name, slug, icon_fallback=icon)
            games.append({
                "id": str(row["id"]),
                "name": name,
                "slug": slug,
                "runner": row["runner"] or "lutris",
                "path": "",
                "icon": cover,
                "cover": cover,
                "run_command": f'xdg-open "lutris:rungame/{slug}"',
            })
    except Exception as e:
        print(f"lutris: {e}", file=sys.stderr)
    return games


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
