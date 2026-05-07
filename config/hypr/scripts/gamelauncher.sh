#!/usr/bin/env bash

LAUNCHER_DIR="$HOME/.local/lib/gamelauncher"
ASSETS_DIR="$HOME/.local/share/gamelauncher/assets"

backend="all"
style="2"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--backend) backend="$2"; shift 2 ;;
        -s|--style)   style="$2";   shift 2 ;;
        *) shift ;;
    esac
done

case "$backend" in
    steam)   script="steam.py" ;;
    lutris)  script="lutris.py" ;;
    desktop) script="desktop.py" ;;
    wine)    script="wine.py" ;;
    *)       script="catalog.py" ;;
esac

# ── Prima esecuzione: setup guidato API key ───────────────────────────────────
_first_run_check() {
    [[ -f "$HOME/.config/gamelauncher/config" ]] && return
    mkdir -p "$HOME/.config/gamelauncher"

    local choice
    choice=$(printf '%s\n' \
        "Configura API key  (copertine per tutti i giochi)" \
        "Continua senza  (copertine automatiche solo per Steam)" | \
        rofi -dmenu -i \
            -p "󰊴  Game Launcher" \
            -mesg $'Benvenuto nel Game Launcher!\n\nIl launcher scarica le copertine automaticamente.\nPer i giochi non-Steam (Lutris, Wine, AUR...)\nserve una <b>API key gratuita</b> di SteamGridDB.\n\nPuoi configurarla ora oppure saltare \xe2\x80\x94 si può aggiungere in qualsiasi momento.' \
            -no-custom \
            -markup \
            -lines 2 \
            -width 58)

    if [[ "$choice" == Configura* ]]; then
        local key
        key=$(rofi -dmenu \
            -p "  Incolla la key" \
            -mesg $'<b>Come ottenerla (1 minuto):</b>\n\n  1. Vai su  <i>https://www.steamgriddb.com</i>  e registrati (gratis)\n  2. Clicca sul tuo avatar in alto a destra\n  3. <b>Preferenze \xe2\x86\x92 API \xe2\x86\x92 Generate Key</b>\n  4. Copia e incolla la key nel campo qui sotto' \
            -markup \
            -lines 0 \
            -width 62 \
            < /dev/null)
        if [[ -n "$key" ]]; then
            echo "STEAMGRIDDB_API_KEY=$key" > "$HOME/.config/gamelauncher/config"
        else
            touch "$HOME/.config/gamelauncher/config"
        fi
    else
        touch "$HOME/.config/gamelauncher/config"
    fi
}

_first_run_check

json_tmp=$(mktemp /tmp/gamelauncher_json.XXXXXX)
rofi_tmp=$(mktemp /tmp/gamelauncher_rofi.XXXXXX)
trap 'rm -f "$json_tmp" "$rofi_tmp"' EXIT

python3 "$LAUNCHER_DIR/$script" --json >"$json_tmp" 2>/dev/null

if [[ ! -s "$json_tmp" ]]; then
    notify-send "Game Launcher" "Nessun gioco trovato (backend: $backend)" 2>/dev/null
    exit 0
fi

# Write rofi entries in binary mode to preserve \x00 icon separators
python3 - "$json_tmp" "$rofi_tmp" <<'PYEOF'
import sys, json
with open(sys.argv[1]) as f:
    games = json.load(f)
with open(sys.argv[2], 'wb') as out:
    for g in games:
        name = g["name"]
        icon = g.get("icon") or g.get("cover") or ""
        line = f"{name}\x00icon\x1f{icon}\n" if icon else f"{name}\n"
        out.write(line.encode("utf-8"))
PYEOF

# Style 5: genera un .rasi temporaneo con dimensioni e griglia calcolate dinamicamente
r_override=""
style5_rasi=""
if [[ "$style" == "5" ]]; then
    py_calc=$(mktemp /tmp/gamelauncher_calc.XXXXXX.py)
    cat > "$py_calc" << 'PYEOF'
import sys, json, math, subprocess
with open(sys.argv[1]) as f:
    count = len(json.load(f))
try:
    r = subprocess.run(['hyprctl','monitors','-j'], capture_output=True, text=True)
    m = next((x for x in json.loads(r.stdout) if x.get('focused')), json.loads(r.stdout)[0])
    sw, sh = m['width'], m['height']
except Exception:
    sw, sh = 1920, 1080
img_ratio = 1731 / 683
max_w, max_h = int(sw * 0.88), int(sh * 0.88)
w = max_w
h = int(w / img_ratio)
if h > max_h:
    h = max_h
    w = int(h * img_ratio)
cols      = min(count, 5)
lines     = math.ceil(count / cols) if cols else 1
icon_size = max(8, 8 + (5 - cols) * 4)  # 5col=8em 4col=12em 3col=16em 2col=20em 1col=24em
print(w, h, cols, lines, icon_size)
PYEOF
    read -r mw mh cols lines icon_size < <(python3 "$py_calc" "$json_tmp" 2>/dev/null)
    rm -f "$py_calc"
    mw=${mw:-1524}; mh=${mh:-601}; cols=${cols:-5}; lines=${lines:-2}; icon_size=${icon_size:-8}

    style5_rasi=$(mktemp /tmp/gamelauncher_style5.XXXXXX.rasi)
    trap 'rm -f "$json_tmp" "$rofi_tmp" "$style5_rasi"' EXIT

    cat > "$style5_rasi" <<RASI
configuration {
    modi:               "drun";
    show-icons:         true;
    drun-display-format:"{name}";
    font:               "JetBrainsMono Nerd Font 8";
}
* {
    main-bg:            #11111be6;
    main-fg:            #cdd6f4ff;
    select-bg:          #b4befeff;
    select-fg:          #11111bff;
    background-color:   transparent;
    text-color:         @main-fg;
}
window {
    width:              ${mw}px;
    height:             ${mh}px;
    transparency:       "real";
    border:             0em;
    border-radius:      0em;
    padding:            0em;
    spacing:            0em;
    background-color:   transparent;
    background-image:   url("$ASSETS_DIR/steamdeck_holographic.png", width);
}
mainbox {
    spacing:            1em;
    padding:            13% 18%;
    children:           [ "inputbar", "listview" ];
    background-color:   transparent;
}
inputbar {
    children:           [ "entry" ];
    background-color:   transparent;
}
entry {
    placeholder:        "Cerca gioco...";
    placeholder-color:  @main-fg;
    background-color:   transparent;
    text-color:         @main-fg;
}
listview {
    columns:            ${cols};
    lines:              ${lines};
    spacing:            2em;
    padding:            0em;
    layout:             vertical;
    scrollbar:          false;
    cycle:              true;
    dynamic:            false;
    fixed-height:       true;
    fixed-columns:      true;
    background-color:   transparent;
}
element {
    orientation:        vertical;
    padding:            0.4em;
    cursor:             pointer;
    background-color:   transparent;
    text-color:         @main-fg;
}
element selected.normal {
    background-color:   @select-bg;
    text-color:         @select-fg;
    border-radius:      0.5em;
}
element-icon {
    size:               ${icon_size}em;
    border-radius:      0.3em;
    background-color:   transparent;
}
element-text {
    vertical-align:     0.5;
    horizontal-align:   0.5;
    padding:            0.4em;
    background-color:   transparent;
    text-color:         inherit;
}
RASI
fi

if [[ "$style" == "5" && -n "$style5_rasi" ]]; then
    config_arg="$style5_rasi"
elif [[ "$style" == "2" ]]; then
    py_calc2=$(mktemp /tmp/gamelauncher_calc2.XXXXXX.py)
    cat > "$py_calc2" << 'PYEOF'
import sys, json, math
with open(sys.argv[1]) as f:
    count = len(json.load(f))
cols      = min(count, 6)
lines     = min(math.ceil(count / cols), 3)
icon_size = max(10, 10 + (6 - cols) * 4)
print(cols, lines, icon_size)
PYEOF
    read -r cols2 lines2 icon_size2 < <(python3 "$py_calc2" "$json_tmp" 2>/dev/null)
    rm -f "$py_calc2"
    cols2=${cols2:-6}; lines2=${lines2:-2}; icon_size2=${icon_size2:-10}

    # Background: cover dell'ultimo gioco lanciato, fallback al wallpaper corrente
    _cache_dir="$HOME/.cache/gamelauncher"
    mkdir -p "$_cache_dir"
    _last_cover=""
    [[ -f "$_cache_dir/last_cover" ]] && _last_cover=$(cat "$_cache_dir/last_cover")
    if [[ -n "$_last_cover" && -f "$_last_cover" ]]; then
        ln -sf "$_last_cover" "$_cache_dir/bg"
    else
        ln -sf "$(readlink -f ~/.config/rofi/.current_wallpaper)" "$_cache_dir/bg"
    fi
    _bg_path="$_cache_dir/bg"

    style2_rasi=$(mktemp /tmp/gamelauncher_style2.XXXXXX.rasi)
    trap 'rm -f "$json_tmp" "$rofi_tmp" "$style5_rasi" "$style2_rasi"' EXIT

    cat > "$style2_rasi" <<RASI
configuration {
    modi:               "drun";
    show-icons:         true;
    drun-display-format:"{name}";
    font:               "JetBrainsMono Nerd Font 8";
}
@theme "~/.config/rofi/wallust/colors-rofi.rasi"
window {
    width:              100%;
    height:             80%;
    transparency:       "real";
    border:             0em;
    border-radius:      0em;
    padding:            0em;
    spacing:            0em;
    background-color:   @background-color;
}
mainbox {
    children:           [ "inputbar", "listview" ];
    background-color:   transparent;
    spacing:            0em;
    padding:            0em;
}
inputbar {
    children:           [ "textbox-prompt-colon", "entry" ];
    background-image:   url("${_bg_path}", width);
    background-color:   transparent;
    padding:            4em;
    spacing:            0em;
}
textbox-prompt-colon {
    str:                " 󰊴 ";
    background-color:   @background;
    text-color:         @foreground;
    padding:            1em 0.5em 1em 1em;
    border-radius:      2em 0em 0em 2em;
    expand:             false;
}
entry {
    background-color:   @background;
    text-color:         @foreground;
    placeholder:        "  Cerca gioco...";
    placeholder-color:  inherit;
    padding:            1em;
    border-radius:      0em 2em 2em 0em;
    spacing:            1em;
    cursor:             text;
}
listview {
    columns:            ${cols2};
    lines:              ${lines2};
    spacing:            3em;
    padding:            3em;
    cycle:              true;
    dynamic:            true;
    scrollbar:          false;
    layout:             vertical;
    fixed-height:       false;
    fixed-columns:      true;
    background-color:   transparent;
    text-color:         @foreground;
}
element {
    orientation:        vertical;
    spacing:            0em;
    padding:            0.5em;
    border-radius:      0em;
    cursor:             pointer;
    background-color:   transparent;
    text-color:         @foreground;
}
element selected.normal {
    background-color:   @color12;
    text-color:         @background-color;
    border-radius:      1em;
}
element-icon {
    size:               ${icon_size2}em;
    spacing:            0em;
    padding:            0em;
    cursor:             inherit;
    border-radius:      3.5em;
    background-color:   transparent;
}
element-text {
    vertical-align:     0.5;
    horizontal-align:   0.5;
    spacing:            0em;
    padding:            0.5em;
    cursor:             inherit;
    background-color:   transparent;
    text-color:         inherit;
}
RASI
    config_arg="$style2_rasi"
else
    config_arg="gamelauncher_${style}"
fi

selected=$(rofi -dmenu -i \
    -config "$config_arg" \
    -p " Giochi" \
    -show-icons \
    -no-custom \
    < "$rofi_tmp")

[[ -z "$selected" ]] && exit 0

cmd=$(python3 - "$json_tmp" "$selected" <<'PYEOF'
import sys, json
with open(sys.argv[1]) as f:
    games = json.load(f)
name = sys.argv[2]
for g in games:
    if g["name"] == name:
        print(g["run_command"])
        break
PYEOF
)

[[ -z "$cmd" ]] && exit 0
eval "$cmd" &>/dev/null &
disown

# Salva il cover del gioco lanciato come background per la prossima apertura
_cover_path=$(python3 - "$json_tmp" "$selected" <<'PYEOF'
import sys, json
with open(sys.argv[1]) as f:
    games = json.load(f)
name = sys.argv[2]
for g in games:
    if g["name"] == name:
        print(g.get("cover") or g.get("icon") or "")
        break
PYEOF
)
if [[ -n "$_cover_path" && -f "$_cover_path" ]]; then
    echo "$_cover_path" > "$HOME/.cache/gamelauncher/last_cover"
fi
