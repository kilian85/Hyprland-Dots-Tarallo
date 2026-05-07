#!/usr/bin/env python3
"""
Cover art resolver per gamelauncher.
Priorità: covers/ (manuale) > cache/ > DuckDuckGo (free) > SteamGridDB (opzionale) > icona
"""

import json
import os
import re
import sys
import urllib.request
import urllib.parse
from pathlib import Path


COVERS_DIR = Path.home() / ".local/share/gamelauncher/covers"
CACHE_DIR  = Path.home() / ".local/share/gamelauncher/cache"
CONFIG     = Path.home() / ".config/gamelauncher/config"
SGDB_BASE  = "https://www.steamgriddb.com/api/v2"
EXTS       = ("jpg", "jpeg", "png", "webp")

HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
}


def _check(directory: Path, slug: str) -> str:
    for ext in EXTS:
        p = directory / f"{slug}.{ext}"
        if p.exists():
            return str(p)
    return ""


def _save(url: str, dest: Path) -> bool:
    try:
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=8) as r:
            dest.write_bytes(r.read())
        return dest.stat().st_size > 1024
    except Exception:
        dest.unlink(missing_ok=True)
        return False


def _ddg_cover(name: str, slug: str) -> str:
    """Cerca la cover su DuckDuckGo Images — gratuito, nessuna registrazione."""
    query = urllib.parse.quote(f"{name} game cover art")
    try:
        # Step 1: ottieni il token vqd
        url = f"https://duckduckgo.com/?q={query}&iax=images&ia=images"
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=8) as r:
            html = r.read().decode("utf-8", errors="replace")

        vqd = re.search(r'vqd=([\d-]+)', html)
        if not vqd:
            return ""
        vqd = vqd.group(1)

        # Step 2: recupera risultati immagini JSON
        api = (f"https://duckduckgo.com/i.js"
               f"?q={query}&vqd={vqd}&o=json&p=1&s=0&u=bing&f=,,,,,&l=us-en")
        req = urllib.request.Request(api, headers={**HEADERS, "Referer": "https://duckduckgo.com/"})
        with urllib.request.urlopen(req, timeout=8) as r:
            results = json.loads(r.read()).get("results", [])

        # Preferisci immagini portrait (altezza > larghezza)
        portrait = [r for r in results if r.get("height", 0) > r.get("width", 0)]
        candidates = (portrait or results)[:5]

        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        dest = CACHE_DIR / f"{slug}.jpg"

        for item in candidates:
            img_url = item.get("image", "")
            if img_url and _save(img_url, dest):
                return str(dest)

    except Exception as e:
        print(f"covers: ddg '{name}': {e}", file=sys.stderr)
    return ""


def _api_key() -> str:
    env = os.environ.get("STEAMGRIDDB_API_KEY", "").strip()
    if env:
        return env
    if not CONFIG.exists():
        return ""
    for line in CONFIG.read_text().splitlines():
        line = line.strip()
        if line.startswith("#") or "=" not in line:
            continue
        if line.startswith("STEAMGRIDDB_API_KEY="):
            val = line.split("=", 1)[1].strip()
            return val if val else ""
    return ""


def _sgdb_fetch(name: str, slug: str, api_key: str) -> str:
    headers = {"Authorization": f"Bearer {api_key}"}
    try:
        url = f"{SGDB_BASE}/search/autocomplete/{urllib.parse.quote(name)}"
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=6) as r:
            results = json.loads(r.read()).get("data", [])
        if not results:
            return ""
        game_id = results[0]["id"]
    except Exception as e:
        print(f"covers: sgdb search '{name}': {e}", file=sys.stderr)
        return ""

    for params in ("?dimensions=600x900&mime=jpg&limit=1", "?mime=jpg&limit=1"):
        try:
            url = f"{SGDB_BASE}/grids/game/{game_id}{params}"
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=6) as r:
                grids = json.loads(r.read()).get("data", [])
            if grids:
                CACHE_DIR.mkdir(parents=True, exist_ok=True)
                dest = CACHE_DIR / f"{slug}.jpg"
                if _save(grids[0]["url"], dest):
                    return str(dest)
                break
        except Exception:
            continue
    return ""


def find_cover(name: str, slug: str = "", icon_fallback: str = "") -> str:
    """
    Risolve la cover art per un gioco.
    Priorità: cover manuale > cache > DuckDuckGo (free) > SteamGridDB > icona sistema
    """
    if not slug:
        slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")

    # 1. Cover manuale dell'utente (massima priorità)
    cover = _check(COVERS_DIR, slug)
    if cover:
        return cover

    # 2. Cache locale (già scaricata in precedenza)
    cover = _check(CACHE_DIR, slug)
    if cover:
        return cover

    # 3. DuckDuckGo — gratuito, nessuna registrazione
    cover = _ddg_cover(name, slug)
    if cover:
        return cover

    # 4. SteamGridDB — opzionale, qualità garantita
    key = _api_key()
    if key:
        cover = _sgdb_fetch(name, slug, key)
        if cover:
            return cover

    # 5. Icona di sistema come fallback
    return icon_fallback
