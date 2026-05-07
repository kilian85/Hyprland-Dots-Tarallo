#!/usr/bin/env bash
# GUI per scegliere il tema SDDM

ASTRONAUT_DIR="/usr/share/sddm/themes/sddm-astronaut-theme"
PREVIEW_DIR="$HOME/.cache/sddm-theme-previews"

# id => pretty name  (formato: "theme_dir::subtheme" per sddm-astronaut, "theme_dir" per standalone)
declare -A PRETTY_NAMES=(
    # Temi standalone
    [simple_sddm_2]="Simple SDDM 2 (attuale)"
    [sugar-candy]="Sugar Candy"
    [elarun]="Elarun"
    [maldives]="Maldives"
    [maya]="Maya"
    # Sotto-temi sddm-astronaut
    [astronaut]="Astronaut"
    [black_hole]="Black Hole"
    [cyberpunk]="Cyberpunk"
    [hyprland_kath]="Hyprland Kath (Video)"
    [hyprland_kath_static]="Hyprland Kath (Statico)"
    [jake_the_dog]="Jake the Dog (Video)"
    [jake_the_dog_static]="Jake the Dog (Statico)"
    [japanese_aesthetic]="Japanese Aesthetic"
    [pixel_sakura]="Pixel Sakura (Animata)"
    [pixel_sakura_static]="Pixel Sakura (Statica)"
    [post-apocalyptic_hacker]="Post-Apocalyptic Hacker"
    [purple_leaves]="Purple Leaves"
)

# Tipo di ogni tema: "standalone" o "astronaut"
declare -A THEME_TYPE=(
    [simple_sddm_2]="standalone"
    [sugar-candy]="standalone"
    [elarun]="standalone"
    [maldives]="standalone"
    [maya]="standalone"
    [astronaut]="astronaut"
    [black_hole]="astronaut"
    [cyberpunk]="astronaut"
    [hyprland_kath]="astronaut"
    [hyprland_kath_static]="astronaut"
    [jake_the_dog]="astronaut"
    [jake_the_dog_static]="astronaut"
    [japanese_aesthetic]="astronaut"
    [pixel_sakura]="astronaut"
    [pixel_sakura_static]="astronaut"
    [post-apocalyptic_hacker]="astronaut"
    [purple_leaves]="astronaut"
)

declare -A ID_BY_NAME=()
for id in "${!PRETTY_NAMES[@]}"; do
    ID_BY_NAME["${PRETTY_NAMES[$id]}"]="$id"
    ID_BY_NAME["${PRETTY_NAMES[$id]} ✓"]="$id"
done

THEME_ORDER=(
    simple_sddm_2 sugar-candy elarun maldives maya
    astronaut black_hole cyberpunk
    hyprland_kath hyprland_kath_static
    jake_the_dog jake_the_dog_static
    japanese_aesthetic pixel_sakura pixel_sakura_static
    post-apocalyptic_hacker purple_leaves
)

# Legge il tema SDDM attivo
CURRENT_SDDM=$(grep "^Current=" /etc/sddm.conf 2>/dev/null | cut -d= -f2)

# Legge il sotto-tema astronaut attivo (se applicabile)
CURRENT_ASTRONAUT=""
if [ "$CURRENT_SDDM" = "sddm-astronaut-theme" ]; then
    CURRENT_MD5=$(md5sum "$ASTRONAUT_DIR/theme.conf" 2>/dev/null | cut -d' ' -f1)
    for conf in "$ASTRONAUT_DIR/Themes/"*.conf; do
        if [ "$(md5sum "$conf" | cut -d' ' -f1)" = "$CURRENT_MD5" ]; then
            CURRENT_ASTRONAUT=$(basename "$conf" .conf)
            break
        fi
    done
fi

# Costruisce la lista rofi
ROFI_INPUT=""
for id in "${THEME_ORDER[@]}"; do
    img="$PREVIEW_DIR/$id.png"
    [ ! -f "$img" ] && img="$PREVIEW_DIR/astronaut.png"
    name="${PRETTY_NAMES[$id]}"
    # Segna il tema attivo
    if [ "${THEME_TYPE[$id]}" = "standalone" ] && [ "$CURRENT_SDDM" = "$id" ]; then
        name="$name ✓"
    elif [ "${THEME_TYPE[$id]}" = "astronaut" ] && [ "$id" = "$CURRENT_ASTRONAUT" ]; then
        name="$name ✓"
    fi
    ROFI_INPUT+="$name\0icon\x1f$img\n"
done

SELECTED_NAME=$(printf "$ROFI_INPUT" | rofi \
    -dmenu \
    -show-icons \
    -columns 3 \
    -lines 6 \
    -p "Tema SDDM" \
    -theme-str 'window { width: 1200px; } element-icon { size: 3.5em; }')

[ -z "$SELECTED_NAME" ] && exit 0

THEME_ID="${ID_BY_NAME[$SELECTED_NAME]}"
[ -z "$THEME_ID" ] && exit 0

PRETTY="${PRETTY_NAMES[$THEME_ID]}"
PREVIEW="$PREVIEW_DIR/$THEME_ID.png"
[ ! -f "$PREVIEW" ] && PREVIEW="$PREVIEW_DIR/astronaut.png"

# Conferma
yad \
    --title="Conferma tema" \
    --center \
    --image="$PREVIEW" \
    --image-on-top \
    --text="\nApplicare il tema <b>$PRETTY</b>?\n" \
    --button="Conferma:0" \
    --button="Annulla:1" || exit 0

# Applica con pkexec
pkexec /usr/local/bin/sddm-theme-apply "${THEME_TYPE[$THEME_ID]}" "$THEME_ID"

if [ $? -eq 0 ]; then
    notify-send -u low -t 4000 "SDDM" "Tema <b>$PRETTY</b> applicato.\nEffettivo al prossimo login."
else
    notify-send -u critical -t 5000 "SDDM" "Errore nell'applicazione del tema."
fi
