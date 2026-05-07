#!/usr/bin/env bash
# Installazione pacchetti opzionali post-installazione

TERM_CMD="${TERMINAL:-kitty}"

install_pkgs() {
    local title="$1"
    shift
    local pkgs=("$@")
    if [[ ${#pkgs[@]} -gt 0 ]]; then
        $TERM_CMD -- bash -c "
            echo '=== Installazione: $title ==='
            yay -S --needed ${pkgs[*]}
            echo ''
            echo 'Fatto! Premi Invio per chiudere.'
            read
        "
    fi
}

show_browser() {
    local choice
    choice=$(yad \
        --title="Installa Browser" \
        --center --width=420 \
        --list \
        --radiolist \
        --column="" --column="Browser" --column="Descrizione" \
        --no-headers \
        --print-column=2 \
        TRUE  "brave-bin"       "Brave" \
        FALSE "chromium"        "Chromium" \
        FALSE "firefox"         "Firefox" \
        FALSE "librewolf-bin"   "LibreWolf" \
        FALSE "opera-gx"        "Opera GX" \
        FALSE "vivaldi"         "Vivaldi" \
        FALSE "zen-browser-bin" "Zen Browser" \
        --button="Installa:0" \
        --button="Annulla:1" 2>/dev/null)
    [[ $? -ne 0 || -z "$choice" ]] && return
    choice=$(echo "$choice" | tr -d '|')
    install_pkgs "Browser" "$choice"
}

show_gaming() {
    local result
    result=$(yad \
        --title="Pacchetti Gaming" \
        --center --width=500 \
        --list \
        --checklist \
        --column="" --column="Pacchetto" --column="Descrizione" \
        --no-headers \
        --print-column=2 \
        FALSE "bottles"                   "Bottles — gestore prefissi Wine" \
        FALSE "heroic-games-launcher-bin" "Heroic — launcher Epic/GOG" \
        FALSE "lutris"                    "Lutris — launcher giochi" \
        FALSE "steam"                     "Steam" \
        FALSE "wine-staging"              "Wine Staging" \
        FALSE "winetricks"                "Winetricks" \
        --button="Installa:0" \
        --button="Annulla:1" 2>/dev/null)
    [[ $? -ne 0 || -z "$result" ]] && return
    local pkgs=()
    while IFS='|' read -r pkg _; do
        [[ -n "$pkg" ]] && pkgs+=("$pkg")
    done <<< "$result"
    [[ ${#pkgs[@]} -gt 0 ]] && install_pkgs "Gaming" "${pkgs[@]}"
}

show_voicechat() {
    local result
    result=$(yad \
        --title="Chat Vocale" \
        --center --width=400 \
        --list \
        --checklist \
        --column="" --column="Pacchetto" --column="Descrizione" \
        --no-headers \
        --print-column=2 \
        FALSE "discord"    "Discord" \
        FALSE "teamspeak3" "TeamSpeak 3" \
        --button="Installa:0" \
        --button="Annulla:1" 2>/dev/null)
    [[ $? -ne 0 || -z "$result" ]] && return
    local pkgs=()
    while IFS='|' read -r pkg _; do
        [[ -n "$pkg" ]] && pkgs+=("$pkg")
    done <<< "$result"
    [[ ${#pkgs[@]} -gt 0 ]] && install_pkgs "Chat Vocale" "${pkgs[@]}"
}

# Menu principale
while true; do
    choice=$(yad \
        --title="Installazione pacchetti opzionali" \
        --center --width=440 \
        --list \
        --column="Categoria" --column="Descrizione" \
        --no-headers \
        --print-column=1 \
        "🌐  Browser"     "Brave, Firefox, Zen, Opera GX..." \
        "🎮  Gaming"      "Steam, Lutris, Bottles, Heroic, Wine..." \
        "🎙️  Chat vocale" "Discord, TeamSpeak 3" \
        --button="Apri:0" \
        --button="Chiudi:1" 2>/dev/null)

    [[ $? -ne 0 ]] && break

    choice=$(echo "$choice" | tr -d '|')
    case "$choice" in
        *Browser*)    show_browser ;;
        *Gaming*)     show_gaming ;;
        *"Chat vocale"*) show_voicechat ;;
    esac
done
