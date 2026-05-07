#!/usr/bin/env python3
"""Steam backend — reads installed games from Steam library manifests."""

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from covers import find_cover as resolve_cover


STEAM_ROOTS = [
    Path.home() / ".local/share/Steam",
    Path.home() / ".steam/steam",
    Path.home() / ".var/app/com.valvesoftware.Steam/.local/share/Steam",
]

EXCLUDE = re.compile(
    r"Proton|Steam Linux Runtime|Steam Runtime|Steamworks Common", re.IGNORECASE
)


def library_paths(root: Path) -> list[Path]:
    paths = [root / "steamapps"]
    vdf = root / "steamapps/libraryfolders.vdf"
    if vdf.exists():
        for m in re.finditer(r'"path"\s+"([^"]+)"', vdf.read_text(errors="replace")):
            p = Path(m.group(1)) / "steamapps"
            if p.exists():
                paths.append(p)
    return [p for p in paths if p.exists()]


STEAM_CDN = "https://cdn.cloudflare.steamstatic.com/steam/apps"
GL_CACHE  = Path.home() / ".local/share/gamelauncher/cache"


def find_cover(root: Path, appid: str) -> str:
    # 1. Cache locale di Steam
    cache = root / "appcache" / "librarycache"
    for suffix in ("library_600x900.jpg", "library_capsule.jpg", "library_hero.jpg", "header.jpg"):
        p = cache / f"{appid}_{suffix}"
        if p.exists():
            return str(p)
    # 2. Cache locale del launcher (scaricata in precedenza)
    cached = GL_CACHE / f"steam-{appid}.jpg"
    if cached.exists():
        return str(cached)
    # 3. Steam CDN — nessuna API key necessaria
    import urllib.request
    GL_CACHE.mkdir(parents=True, exist_ok=True)
    for suffix in ("library_600x900.jpg", "library_capsule.jpg", "header.jpg"):
        url = f"{STEAM_CDN}/{appid}/{suffix}"
        try:
            urllib.request.urlretrieve(url, cached)
            return str(cached)
        except Exception:
            continue
    return ""


def list_games() -> list[dict]:
    games: list[dict] = []
    seen: set[str] = set()
    for root in STEAM_ROOTS:
        if not root.exists():
            continue
        for lib in library_paths(root):
            for acf in lib.glob("appmanifest_*.acf"):
                text = acf.read_text(errors="replace")
                m_id = re.search(r'"appid"\s+"(\d+)"', text)
                m_name = re.search(r'"name"\s+"([^"]+)"', text)
                if not m_id or not m_name:
                    continue
                appid, name = m_id.group(1), m_name.group(1)
                if EXCLUDE.search(name) or appid in seen:
                    continue
                seen.add(appid)
                steam_cover = find_cover(root, appid)
                slug = f"steam-{appid}"
                cover = resolve_cover(name, slug, icon_fallback=steam_cover)
                games.append({
                    "id": appid,
                    "name": name,
                    "slug": slug,
                    "runner": "steam",
                    "path": str(lib),
                    "icon": cover,
                    "cover": cover,
                    "run_command": f"xdg-open steam://rungameid/{appid}",
                })
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
