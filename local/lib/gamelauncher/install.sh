#!/usr/bin/env bash
# Installer del Game Launcher standalone per Hyprland + Rofi
# Uso: bash install.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

banner() {
    echo ""
    echo -e "${BLUE}${BOLD}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}${BOLD}║       Game Launcher — Installer      ║${NC}"
    echo -e "${BLUE}${BOLD}╚══════════════════════════════════════╝${NC}"
    echo ""
}

step() { echo -e "\n${GREEN}${BOLD}[$1]${NC} $2"; }
info() { echo -e "    ${BLUE}→${NC} $1"; }
warn() { echo -e "    ${YELLOW}⚠${NC}  $1"; }
ok()   { echo -e "    ${GREEN}✓${NC}  $1"; }

# ── Controllo dipendenze ──────────────────────────────────────────────────────
check_deps() {
    step "1/4" "Controllo dipendenze..."
    local missing=()
    for dep in rofi python3 hyprctl wget; do
        if command -v "$dep" &>/dev/null; then
            ok "$dep trovato"
        else
            missing+=("$dep")
            warn "$dep NON trovato"
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Dipendenze mancanti: ${missing[*]}${NC}"
        echo "Installa con: yay -S ${missing[*]}"
        exit 1
    fi
}

# ── Copia file ────────────────────────────────────────────────────────────────
install_files() {
    step "2/4" "Installo i file..."

    mkdir -p \
        "$HOME/.local/lib/gamelauncher" \
        "$HOME/.local/bin" \
        "$HOME/.config/gamelauncher" \
        "$HOME/.local/share/gamelauncher/covers" \
        "$HOME/.local/share/gamelauncher/cache"

    cp "$REPO_DIR"/*.py "$HOME/.local/lib/gamelauncher/"
    cp "$REPO_DIR/gamelauncher.sh" "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/gamelauncher.sh"

    ok "File copiati"
}

# ── API key SteamGridDB (opzionale) ──────────────────────────────────────────
setup_covers() {
    step "3/4" "Copertine dei giochi"
    echo ""
    echo "    Il launcher scarica automaticamente le copertine per i giochi Steam."
    echo "    Per i giochi non-Steam (AUR, Wine...) serve una API key gratuita"
    echo "    di SteamGridDB che permette di scaricare copertine per qualsiasi gioco."
    echo ""
    echo -e "    ${BOLD}Come ottenerla (1 minuto):${NC}"
    echo "      1. Vai su  https://www.steamgriddb.com  e registrati (gratuito)"
    echo "      2. Vai su  Profilo → Preferenze → API"
    echo "      3. Clicca 'Genera key' e incollala qui sotto"
    echo ""

    # Controlla se già configurata
    local current_key=""
    current_key=$(grep -s "^STEAMGRIDDB_API_KEY=" "$HOME/.config/gamelauncher/config" | cut -d= -f2)
    if [[ -n "$current_key" ]]; then
        ok "API key già configurata"
        return
    fi

    read -rp "    API key SteamGridDB (Invio per saltare): " apikey
    echo ""

    if [[ -n "$apikey" ]]; then
        echo "STEAMGRIDDB_API_KEY=$apikey" > "$HOME/.config/gamelauncher/config"
        ok "API key salvata in ~/.config/gamelauncher/config"
    else
        warn "Saltato — le copertine Steam funzionano lo stesso"
        info "Puoi aggiungere la key in qualsiasi momento:"
        info "  echo 'STEAMGRIDDB_API_KEY=tuakey' > ~/.config/gamelauncher/config"
    fi
}

# ── Keybinding Hyprland (opzionale) ──────────────────────────────────────────
setup_keybind() {
    step "4/4" "Keybinding Hyprland (opzionale)"
    echo ""
    echo "    Vuoi aprire il launcher con SUPER+G?"
    read -rp "    Aggiungi keybinding a hyprland.conf? [S/n]: " answer
    echo ""

    if [[ "${answer,,}" != "n" ]]; then
        local conf="$HOME/.config/hypr/hyprland.conf"
        if grep -q "gamelauncher" "$conf" 2>/dev/null; then
            ok "Keybinding già presente"
        else
            echo "" >> "$conf"
            echo "bind = SUPER, G, exec, gamelauncher.sh" >> "$conf"
            ok "Aggiunto: bind = SUPER, G, exec, gamelauncher.sh"
        fi
    else
        info "Saltato — puoi aggiungere manualmente in hyprland.conf:"
        info "  bind = SUPER, G, exec, gamelauncher.sh"
    fi
}

# ── Riepilogo finale ──────────────────────────────────────────────────────────
summary() {
    echo ""
    echo -e "${BLUE}${BOLD}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  Installazione completata!${NC}"
    echo -e "${BLUE}${BOLD}══════════════════════════════════════════${NC}"
    echo ""
    echo "  Comandi disponibili:"
    echo "    gamelauncher.sh           → apri il launcher"
    echo "    gamelauncher.sh -b steam  → solo giochi Steam"
    echo "    gamelauncher.sh -b lutris → solo giochi Lutris"
    echo "    gamelauncher.sh -b wine   → solo giochi Wine"
    echo ""
    echo "  Covers manuali:"
    echo "    ~/.local/share/gamelauncher/covers/nome-gioco.jpg"
    echo ""
}

banner
check_deps
install_files
setup_covers
setup_keybind
summary
