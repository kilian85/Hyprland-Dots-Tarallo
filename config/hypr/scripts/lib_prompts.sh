#!/usr/bin/env bash
# User interaction helpers extracted from copy.sh. Each helper echoes state or sets
# globals deliberately to minimize side effects.

# Detect keyboard layout via localectl or setxkbmap.
prompt_detect_layout() {
  if command -v localectl >/dev/null 2>&1; then
    local layout
    layout=$(localectl status --no-pager | awk '/X11 Layout/ {print $3}')
    [ -n "$layout" ] && { echo "$layout"; return; }
  fi
  if command -v setxkbmap >/dev/null 2>&1; then
    local layout
    layout=$(setxkbmap -query | awk '/layout/ {print $2}')
    [ -n "$layout" ] && { echo "$layout"; return; }
  fi
  echo "(unset)"
}

# Confirm or set keyboard layout; writes to SystemSettings.conf.
prompt_keyboard_layout() {
  local layout="$1"
  local log="$2"

  if [ "$layout" = "(unset)" ]; then
    while true; do
      printf "\n%.0s" {1..1}
      print_color $WARNING "\n    █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
            ATTENZIONE LEGGERE
    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█

    !!! AVVISO IMPORTANTE !!!

Il layout tastiera predefinito non è stato rilevato
Devi impostarlo manualmente

    !!! ATTENZIONE !!!

Impostare un layout tastiera errato farà crashare Hyprland
Se non sei sicuro, digita ${YELLOW}us${RESET}
${SKYBLUE}Puoi cambiarlo in seguito in ~/.config/hypr/UserConfigs/UserSettings.conf${RESET}

${MAGENTA} NOTA:${RESET}
•  Puoi anche impostare più di 2 layout tastiera
•  Per esempio: ${YELLOW}us, kr, gb, ru${RESET}
"
      printf "\n%.0s" {1..1}

      echo -n "${CAT} - Inserisci il layout tastiera corretto: "
      read new_layout

      if [ -n "$new_layout" ]; then
        layout="$new_layout"
        break
      else
        echo "${CAT} Inserisci un layout tastiera."
      fi
    done
  fi

  printf "${NOTE} Rilevamento layout tastiera per preparare le impostazioni Hyprland\n"
  while true; do
    printf "${INFO} Il layout tastiera attuale è ${MAGENTA}$layout${RESET}\n"
    echo -n "${CAT} È corretto? [s/n] "
    read keyboard_layout
    case $keyboard_layout in
      [yYsS])
        awk -v layout="$layout" '/kb_layout/ {$0 = "  kb_layout = " layout} 1' config/hypr/configs/SystemSettings.conf >temp.conf
        mv temp.conf config/hypr/configs/SystemSettings.conf
        echo "${NOTE} kb_layout ${MAGENTA}$layout${RESET} configurato nelle impostazioni." 2>&1 | tee -a "$log"
        break
        ;;
      [nN])
        printf "\n%.0s" {1..2}
        print_color $WARNING "
    █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
            ATTENZIONE LEGGERE
    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█

    !!! AVVISO IMPORTANTE !!!

Il layout tastiera predefinito non è stato rilevato
Devi impostarlo manualmente

    !!! ATTENZIONE !!!

Impostare un layout tastiera errato farà crashare Hyprland
Se non sei sicuro, digita ${YELLOW}us${RESET}
${SKYBLUE}Puoi cambiarlo in seguito in ~/.config/hypr/UserConfigs/UserSettings.conf${RESET}

${MAGENTA} NOTA:${RESET}
•  Puoi anche impostare più di 2 layout tastiera
•  Per esempio: ${YELLOW}us, kr, gb, ru${RESET}
"
        printf "\n%.0s" {1..1}
        echo -n "${CAT} - Inserisci il layout tastiera corretto: "
        read new_layout
        awk -v new_layout="$new_layout" '/kb_layout/ {$0 = "  kb_layout = " new_layout} 1' config/hypr/configs/SystemSettings.conf >temp.conf
        mv temp.conf config/hypr/configs/SystemSettings.conf
        echo "${OK} kb_layout $new_layout configurato nelle impostazioni." 2>&1 | tee -a "$log"
        break
        ;;
      *)
        echo "${ERROR} Inserisci 's' o 'n'."
        ;;
    esac
  done
}

# Prompt for resolution choice; echoes "< 1440p" or "≥ 1440p".
prompt_resolution_choice() {
  local choice
  while true; do
    echo "${INFO:-[INFO]} Seleziona la risoluzione del monitor per la scalatura:"
    echo "  1) < 1440p   (DPI basso; schermi piccoli)"
    echo "  2) ≥ 1440p   (predefinito; 1440p/2k/4k)"

    if ! read -r -p "${CAT} Inserisci il numero della tua scelta (1 o 2): " choice </dev/tty; then
      echo "${ERROR} Impossibile leggere l'input (tty non disponibile)."
      continue
    fi
    echo "${INFO:-[INFO]} Hai inserito: '$choice'"
    case "$choice" in
      1) echo "< 1440p"; return ;;
      2) echo "≥ 1440p"; return ;;
      *) echo "${ERROR} Scelta non valida. Inserisci 1 per < 1440p o 2 per ≥ 1440p." ;;
    esac
  done
}

# Prompt for 12H clock; sets waybar/hyprlock/SDDM changes when accepted.
prompt_clock_12h() {
  local log="$1"
  while true; do
    echo -e "${NOTE} ${SKY_BLUE} Per impostazione predefinita, i Dots sono configurati nel formato 24H."
    echo -n "$CAT Vuoi passare al formato 12H (AM/PM)? (s/n): "
    read answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    if [[ "$answer" == "y" || "$answer" == "s" ]]; then
      # waybar clocks
      sed -i 's#^\(\s*\)//\("format": " {:%I:%M %p}",\) #\1\2 #g' config/waybar/Modules 2>&1 | tee -a "$log"
      sed -i 's#^\(\s*\)\("format": " {:%H:%M:%S}",\) #\1//\2#g' config/waybar/Modules 2>&1 | tee -a "$log"
      sed -i 's#^\(\s*\)\("format": "  {:%H:%M}",\) #\1//\2#g' config/waybar/Modules 2>&1 | tee -a "$log"
      sed -i 's#^\(\s*\)//\("format": "{:%I:%M %p - %d/%b}",\) #\1\2#g' config/waybar/Modules 2>&1 | tee -a "$log"
      sed -i 's#^\(\s*\)\("format": "{:%H:%M - %d/%b}",\) #\1//\2#g' config/waybar/Modules 2>&1 | tee -a "$log"
      sed -i 's#^\(\s*\)//\("format": "{:%B | %a %d, %Y | %I:%M %p}",\) #\1\2#g' config/waybar/Modules 2>&1 | tee -a "$log"
      sed -i 's#^\(\s*\)\("format": "{:%B | %a %d, %Y | %H:%M}",\) #\1//\2#g' config/waybar/Modules 2>&1 | tee -a "$log"
      sed -i 's#^\(\s*\)//\("format": "{:%A, %I:%M %P}",\) #\1\2#g' config/waybar/Modules 2>&1 | tee -a "$log"
      sed -i 's#^\(\s*\)\("format": "{:%a %d | %H:%M}",\) #\1//\2#g' config/waybar/Modules 2>&1 | tee -a "$log"

      # hyprlock
      local HYPRLOCK_FILE="config/hypr/hyprlock.conf"
      if [ ! -f "$HYPRLOCK_FILE" ] && [ -f "config/hypr/hyprlock-1080p.conf" ]; then
        HYPRLOCK_FILE="config/hypr/hyprlock-1080p.conf"
      fi
      if [ -f "$HYPRLOCK_FILE" ]; then
        sed -i 's/^\s*text = cmd\[update:1000\] echo \"\$(date +\"%H\")\"/# &/' "$HYPRLOCK_FILE" 2>&1 | tee -a "$log"
        sed -i 's/^\(\s*\)# *text = cmd\[update:1000\] echo \"\$(date +\"%I\")\" #AM\/PM/\1    text = cmd\[update:1000\] echo \"\$(date +\"%I\")\" #AM\/PM/' "$HYPRLOCK_FILE" 2>&1 | tee -a "$log"
        sed -i 's/^\s*text = cmd\[update:1000\] echo \"\$(date +\"%S\")\"/# &/' "$HYPRLOCK_FILE" 2>&1 | tee -a "$log"
        sed -i 's/^\(\s*\)# *text = cmd\[update:1000\] echo \"\$(date +\"%S %p\")\" #AM\/PM/\1    text = cmd\[update:1000\] echo \"\$(date +\"%S %p\")\" #AM\/PM/' "$HYPRLOCK_FILE" 2>&1 | tee -a "$log"
      else
        echo "${WARN} Template hyprlock non trovato; salto le modifiche al formato 12H" 2>&1 | tee -a "$log"
      fi

      if [ "${EXPRESS_MODE:-0}" -eq 0 ]; then
        apply_sddm_12h_format "/usr/share/sddm/themes/simple-sddm" "$log"
        apply_sddm_12h_format "/usr/share/sddm/themes/simple_sddm_2" "$log"
        apply_sddm_12h_format_sequoia "/usr/share/sddm/themes/sequoia_2" "$log"
      else
        echo "${NOTE:-[NOTE]} Modalità express: salto le modifiche SDDM 12H per evitare prompt sudo." 2>&1 | tee -a "$log"
      fi
      echo "${OK} Formato 12H impostato sui clock waybar con successo." 2>&1 | tee -a "$log"
      return
    elif [[ "$answer" == "n" ]]; then
      echo "${NOTE} Hai scelto di non passare al formato 12H." 2>&1 | tee -a "$log"
      return
    else
      echo "${ERROR} Scelta non valida. Inserisci s per sì o n per no."
    fi
  done
}

apply_sddm_12h_format() {
  local sddm_directory="$1"
  local log="$2"
  if [ -d "$sddm_directory" ]; then
    echo "Modifica ${SKY_BLUE}$sddm_directory${RESET} al formato 12H" 2>&1 | tee -a "$log"
    if ! sudo -n sed -i 's|^## HourFormat="hh:mm AP"|HourFormat="hh:mm AP"|' "$sddm_directory/theme.conf" 2>&1 | tee -a "$log"; then
      echo "${WARN:-[WARN]} Salto modifica SDDM 12H (password sudo richiesta)." 2>&1 | tee -a "$log"
      return
    fi
    sudo -n sed -i 's|^HourFormat="HH:mm"|## HourFormat="HH:mm"|' "$sddm_directory/theme.conf" 2>&1 | tee -a "$log" || true
  fi
}

apply_sddm_12h_format_sequoia() {
  local sddm_directory="$1"
  local log="$2"
  if [ -d "$sddm_directory" ]; then
    echo "${YELLOW}sddm sequoia_2${RESET} tema rilevato. Modifica al formato 12H" 2>&1 | tee -a "$log"
    if ! sudo -n sed -i 's|^clockFormat="HH:mm"|## clockFormat="HH:mm"|' "$sddm_directory/theme.conf" 2>&1 | tee -a "$log"; then
      echo "${WARN:-[WARN]} Salto modifica sequoia SDDM 12H (password sudo richiesta)." 2>&1 | tee -a "$log"
      return
    fi
    if ! grep -q 'clockFormat="hh:mm AP"' "$sddm_directory/theme.conf"; then
      sudo -n sed -i '/^clockFormat=/a clockFormat="hh:mm AP"' "$sddm_directory/theme.conf" 2>&1 | tee -a "$log" || true
    fi
    echo "${OK} Formato 12H impostato su SDDM con successo." 2>&1 | tee -a "$log"
  fi
}


# Express upgrade confirmation; may set EXPRESS_MODE=1.
prompt_rainbow_borders() {
  local log="$1"
  RAINBOW_BORDERS_ENABLED=false
  while true; do
    echo -e "${NOTE} ${SKY_BLUE} I bordi animati delle finestre seguono i colori del wallpaper (richiede più CPU)."
    echo -n "$CAT Vuoi abilitare i bordi animati? (s/n): "
    read -r answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    if [[ "$answer" == "y" || "$answer" == "s" ]]; then
      echo "${OK} Bordi animati verranno abilitati." 2>&1 | tee -a "$log"
      RAINBOW_BORDERS_ENABLED=true
      return
    elif [[ "$answer" == "n" ]]; then
      echo "${NOTE} Bordi animati disabilitati." 2>&1 | tee -a "$log"
      return
    else
      echo "${ERROR} Scelta non valida. Inserisci s per sì o n per no."
    fi
  done
}

prompt_express_upgrade() {
  local express_supported="$1"
  local log="$2"
  if [ "$EXPRESS_MODE" -eq 1 ] && [ "$express_supported" -eq 0 ]; then
    echo "${NOTE} La modalità express richiede i dotfile installati v${MIN_EXPRESS_VERSION} o più recenti. Continuo con i prompt standard." 2>&1 | tee -a "$log"
    EXPRESS_MODE=0
    return
  fi
  if [ "$UPGRADE_MODE" -eq 1 ] && [ "$EXPRESS_MODE" -eq 0 ]; then
    if [ "$express_supported" -eq 0 ]; then
      echo "${NOTE} La modalità express richiede i dotfile installati v${MIN_EXPRESS_VERSION} o più recenti. Continuo con i prompt standard." 2>&1 | tee -a "$log"
    else
      while true; do
        echo "${NOTE} La modalità express salta i prompt di ripristino configurazione, le domande SDDM/sfondo e riduce i backup vecchi."
        if ! read -r -p "${CAT} Vuoi continuare con la modalità di aggiornamento EXPRESS? (s/N): " express_choice </dev/tty; then
          echo "${ERROR} Impossibile leggere l'input per la scelta express; uso i prompt standard." 2>&1 | tee -a "$log"
          break
        fi
        case "$express_choice" in
          [YySs])
            EXPRESS_MODE=1
            echo "${INFO} Modalità express attivata per questo aggiornamento." 2>&1 | tee -a "$log"
            break
            ;;
          [Nn] | "")
            echo "${NOTE} Continuo con i prompt di aggiornamento standard." 2>&1 | tee -a "$log"
            break
            ;;
          *)
            echo "${WARN} Rispondere s o n."
            ;;
        esac
      done
    fi
  fi
}
