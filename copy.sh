#!/usr/bin/env bash
# Purpose:
#   Handles interactive prompts, backups/restores, per-app tweaks, and express mode.
#
# Layout (high-level; future modularization targets):
#   - Constants/colors, helper sourcing (copy_menu.sh, lib_backup.sh, lib_detect.sh, lib_prompts.sh, lib_apps.sh, lib_copy.sh).
#   - New update helper (lib_update.sh) provides menu-driven repo update: verifies Hyprland-Dots root, stashes changes, git pull, logs, summarizes, waits for keypress.
#   - Version helpers and CLI parsing (install/upgrade/express).
#   - Safety checks (non-root), banners/notices.
#   - Environment/distro checks and warnings.
#   - GPU/VM/NixOS detection tweaks (lib_detect.sh).
#   - Input prompts (keyboard, resolution, clock format, animations) (lib_prompts.sh).
#   - Workflow selection effects (express vs standard).
#   - Backup/restore helpers (in scripts/lib_backup.sh).
#   - App enablement/editor selection (lib_apps.sh).
#   - Copy phases (lib_copy.sh):
#       * Part 1: fastfetch/kitty/rofi/swaync (prompted replace).
#       * Waybar special handling (symlinks, configs/styles restore).
#       * Part 2: other configs (btop, cava, hypr, etc.) + ghostty/wezterm installs.
#   - UserConfigs/UserScripts and hypr file restores.
#   - Wallpaper handling (default + optional 1GB pack).
#   - Backup cleanup (auto in express).
#   - Final symlinks (waybar) and wallust init.
#
# Next modular steps:
#   - Restore logic has been moved into lib_copy helpers; review for further
#     consolidation or tests.
#   - Consider modularizing remaining app-specific tweaks/prompts.

clear
wallpaper=$HOME/.config/hypr/wallpaper_effects/.wallpaper_current
waybar_style="$HOME/.config/waybar/style/[Extra] Neon Circuit.css"
waybar_config="$HOME/.config/waybar/configs/[TOP] Default"
waybar_config_laptop="$HOME/.config/waybar/configs/[TOP] Default Laptop"

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"
MIN_EXPRESS_VERSION="2.3.18"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_HELPER="$SCRIPT_DIR/scripts/copy_menu.sh"
BACKUP_HELPER="$SCRIPT_DIR/scripts/lib_backup.sh"
DETECT_HELPER="$SCRIPT_DIR/scripts/lib_detect.sh"
PROMPTS_HELPER="$SCRIPT_DIR/scripts/lib_prompts.sh"
APPS_HELPER="$SCRIPT_DIR/scripts/lib_apps.sh"
COPY_HELPER="$SCRIPT_DIR/scripts/lib_copy.sh"
UPDATE_HELPER="$SCRIPT_DIR/scripts/lib_update.sh"
if [ -f "$MENU_HELPER" ]; then
  # shellcheck source=./scripts/copy_menu.sh
  . "$MENU_HELPER"
fi
if [ -f "$BACKUP_HELPER" ]; then
  # shellcheck source=./scripts/lib_backup.sh
  . "$BACKUP_HELPER"
else
  echo "${ERROR} Backup helper not found at $BACKUP_HELPER. Exiting."
  exit 1
fi
if [ -f "$DETECT_HELPER" ]; then
  # shellcheck source=./scripts/lib_detect.sh
  . "$DETECT_HELPER"
else
  echo "${ERROR} Detect helper not found at $DETECT_HELPER. Exiting."
  exit 1
fi
if [ -f "$PROMPTS_HELPER" ]; then
  # shellcheck source=./scripts/lib_prompts.sh
  . "$PROMPTS_HELPER"
else
  echo "${ERROR} Prompts helper not found at $PROMPTS_HELPER. Exiting."
  exit 1
fi
if [ -f "$APPS_HELPER" ]; then
  # shellcheck source=./scripts/lib_apps.sh
  . "$APPS_HELPER"
else
  echo "${ERROR} Apps helper not found at $APPS_HELPER. Exiting."
  exit 1
fi
if [ -f "$COPY_HELPER" ]; then
  # shellcheck source=./scripts/lib_copy.sh
  . "$COPY_HELPER"
else
  echo "${ERROR} Copy helper not found at $COPY_HELPER. Exiting."
  exit 1
fi
if [ -f "$UPDATE_HELPER" ]; then
  # shellcheck source=./scripts/lib_update.sh
  . "$UPDATE_HELPER"
else
  echo "${ERROR} Update helper not found at $UPDATE_HELPER. Exiting."
  exit 1
fi

version_gte() {
  [ "$1" = "$(echo -e "$1\n$2" | sort -V | tail -n1)" ]
}

get_installed_dotfiles_version() {
  local hypr_dir="$HOME/.config/hypr"
  if [ -d "$hypr_dir" ]; then
    # Pick the highest semantic version among files named vX.Y.Z
    find "$hypr_dir" -maxdepth 1 -type f -name 'v*.*.*' -printf '%f\n' 2>/dev/null \
      | sed 's/^v//' \
      | sort -V \
      | tail -n1
  fi
}

express_supported() {
  local current_version
  current_version=$(get_installed_dotfiles_version)
  if [ -z "$current_version" ]; then
    return 1
  fi
  version_gte "$current_version" "$MIN_EXPRESS_VERSION"
}
print_usage() {
  cat <<'EOF'
Usage: copy.sh [--upgrade] [--express-upgrade] [--help]

Options:
  --upgrade           Run the script in upgrade mode (can still prompt for express).
  --express-upgrade   Upgrade with express behavior (no restore prompts, trims backups).
  -h, --help          Show this help message and exit.
EOF
}

UPGRADE_MODE=0
EXPRESS_MODE=0
RUN_MODE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
  --upgrade)
    UPGRADE_MODE=1
    RUN_MODE="upgrade"
    ;;
  --express-upgrade)
    UPGRADE_MODE=1
    EXPRESS_MODE=1
    RUN_MODE="express"
    ;;
  -h | --help)
    print_usage
    exit 0
    ;;
  *)
    echo "${ERROR} Unknown option: $1"
    print_usage
    exit 1
    ;;
  esac
  shift
done
INSTALLED_VERSION=$(get_installed_dotfiles_version)
EXPRESS_SUPPORTED=0
if express_supported; then
  EXPRESS_SUPPORTED=1
fi
if [ "$EXPRESS_MODE" -eq 1 ] && [ "$EXPRESS_SUPPORTED" -eq 0 ]; then
  echo "${WARN} Express upgrade requires installed dotfiles v${MIN_EXPRESS_VERSION} or newer. Falling back to standard upgrade."
  EXPRESS_MODE=0
  RUN_MODE="upgrade"
fi

if [ -z "$RUN_MODE" ]; then
  if declare -f show_copy_menu >/dev/null 2>&1; then
    while [ -z "$RUN_MODE" ]; do
      show_copy_menu "$EXPRESS_SUPPORTED"
      choice_lower=$(echo "$COPY_MENU_CHOICE" | tr '[:upper:]' '[:lower:]')
      case "$choice_lower" in
      install)
        RUN_MODE="install"
        UPGRADE_MODE=0
        EXPRESS_MODE=0
        ;;
      upgrade)
        RUN_MODE="upgrade"
        UPGRADE_MODE=1
        EXPRESS_MODE=0
        ;;
      express)
        if [ "$EXPRESS_SUPPORTED" -eq 0 ]; then
          echo "${WARN} Express mode requires installed dotfiles v${MIN_EXPRESS_VERSION} or newer. Please choose another option."
          continue
        fi
        RUN_MODE="express"
        UPGRADE_MODE=1
        EXPRESS_MODE=1
        ;;
      update)
        run_repo_update "$SCRIPT_DIR"
        # After update, continue showing the menu without exiting
        continue
        ;;
      quit)
        echo "${NOTE} Exiting per user selection."
        exit 0
        ;;
      *)
        echo "${WARN} Invalid selection."
        ;;
      esac
    done
  else
    echo "${NOTE} Menu helper not found; defaulting to install workflow."
    RUN_MODE="install"
  fi
fi

# Check if running as root. If root, script will exit
if [[ $EUID -eq 0 ]]; then
  echo "${ERROR}  This script should ${WARNING}NOT${RESET} be executed as root!! Exiting......."
  printf "\n%.0s" {1..2}
  exit 1
fi

# Function to print colorful text
print_color() {
  # Use %b for the message to interpret backslash escapes like \n, \t, etc.
  printf "%b%b%b\n" "$1" "$2" "$RESET"
}

# Check /etc/os-release for Ubuntu or Debian and warn about Hyprland version requirement
if grep -iqE '^(ID_LIKE|ID)=.*(ubuntu|debian)' /etc/os-release >/dev/null 2>&1; then
  printf "\n%.0s" {1..1}
  print_color $WARNING "\nQuesti Dotfile sono supportati solo su Hyprland v0.50 o superiore. Non installare su versioni precedenti di Hyprland.\n"
  while true; do
    echo -n "${CAT} Vuoi continuare comunque? (s/N): "
    read _continue
    _continue=$(echo "${_continue}" | tr '[:upper:]' '[:lower:]')
    case "${_continue}" in
    s | si | y | yes)
      echo "${NOTE} Procedo su Ubuntu/Debian per conferma utente."
      break
      ;;
    n | no | "")
      printf "\n%.0s" {1..1}
      echo "${INFO} Interruzione per scelta utente. Nessuna modifica effettuata."
      printf "\n%.0s" {1..1}
      exit 1
      ;;
    *)
      echo "${WARN} Rispondere con 's' o 'n'."
      ;;
    esac
  done
fi

printf "\n%.0s" {1..2}
echo -e "\e[35m
	╔╦╗╔═╗╔═╗╔═╗╦  ╦  ╔═╗   ╦ ╦╗ ╔╔═╗╔═╗╦  ╔═╗╔╗╔╔╦╗
	 ║ ╠═╣╠╦╝╠═╣║  ║  ║ ║   ╠═╣╚╦╝╠═╝╠╦╝║  ╠═╣║║║ ║║ 2026
	 ╩ ╝ ╚╩╚═╝ ╚╩═╝╩═╝╚═╝   ╩ ╩ ╩ ╩  ╩╚═╩═╝╝ ╚╝╚╝═╩╝
\e[0m"
printf "\n%.0s" {1..1}

####### Announcement
echo "${WARNING}A T T E N Z I O N E !${RESET}"
echo "${MAGENTA}Visita il Wiki di Hyprland Tarallo per le ultime modifiche${RESET}"
printf "\n%.0s" {1..1}

# Create Directory for Copy Logs
if [ ! -d Copy-Logs ]; then
  mkdir Copy-Logs
fi

# Set the name of the log file to include the current date and time
LOG="Copy-Logs/install-$(date +%d-%H%M%S)_dotfiles.log"

# update home directories
xdg-user-dirs-update 2>&1 | tee -a "$LOG" || true
echo "${INFO} Modalità selezionata: ${RUN_MODE}" 2>&1 | tee -a "$LOG"
if [ "$UPGRADE_MODE" -eq 1 ]; then
  echo "${INFO} Modalità aggiornamento attivata." 2>&1 | tee -a "$LOG"
fi
if [ "$EXPRESS_MODE" -eq 1 ]; then
  echo "${INFO} Modalità express attivata. I prompt opzionali di ripristino verranno saltati." 2>&1 | tee -a "$LOG"
fi

detect_nvidia_adjust "$LOG"
detect_vm_adjust "$LOG"
detect_nixos_adjust "$LOG"

# activating hyprcursor on env by checking if the directory ~/.icons/Bibata-Modern-Ice/hyprcursors exists
if [ -d "$HOME/.icons/Bibata-Modern-Ice/hyprcursors" ]; then
  HYPRCURSOR_ENV_FILE="config/hypr/configs/ENVariables.conf"
  echo "${INFO} Bibata-Hyprcursor directory detected. Activating Hyprcursor...." 2>&1 | tee -a "$LOG" || true
  sed -i 's/^#env = HYPRCURSOR_THEME,Bibata-Modern-Ice/env = HYPRCURSOR_THEME,Bibata-Modern-Ice/' "$HYPRCURSOR_ENV_FILE"
  sed -i 's/^#env = HYPRCURSOR_SIZE,24/env = HYPRCURSOR_SIZE,24/' "$HYPRCURSOR_ENV_FILE"
fi

printf "\n%.0s" {1..1}

layout=$(prompt_detect_layout)
prompt_keyboard_layout "$layout" "$LOG"

enable_asusctl "$LOG"
enable_blueman "$LOG"
enable_ags "$LOG"
enable_quickshell "$LOG"
ensure_keybinds_init "$LOG"

printf "\n%.0s" {1..1}

choose_default_editor "$LOG"
resolution=""
while true; do
  echo "${INFO} Seleziona la risoluzione del monitor per la scalatura:"
  echo "  1) < 1440p   (DPI basso; schermi piccoli)"
  echo "  2) ≥ 1440p   (predefinito; 1440p/2k/4k)"
  echo -n "${CAT} Inserisci il numero della tua scelta (1 o 2): "
  read -r choice
  case "$choice" in
    1) resolution="< 1440p"; break ;;
    2) resolution="≥ 1440p"; break ;;
    *) echo "${ERROR} Scelta non valida. Inserisci 1 o 2.";;
  esac
done
echo "${OK} Hai scelto la risoluzione $resolution." 2>&1 | tee -a "$LOG"
if [ "$resolution" == "< 1440p" ]; then
  # kitty font size
  sed -i 's/font_size 16.0/font_size 14.0/' config/kitty/kitty.conf

  # hyprlock matters
  if [ -f config/hypr/hyprlock.conf ]; then
    mv config/hypr/hyprlock.conf config/hypr/hyprlock-2k.conf
  fi
  if [ -f config/hypr/hyprlock-1080p.conf ]; then
    mv config/hypr/hyprlock-1080p.conf config/hypr/hyprlock.conf
  fi

  # rofi fonts reduction
  rofi_config_file="config/rofi/0-shared-fonts.rasi"
  if [ -f "$rofi_config_file" ]; then
    sed -i '/element-text {/,/}/s/[[:space:]]*font: "JetBrainsMono Nerd Font SemiBold 13"/font: "JetBrainsMono Nerd Font SemiBold 11"/' "$rofi_config_file" 2>&1 | tee -a "$LOG"
    sed -i '/configuration {/,/}/s/[[:space:]]*font: "JetBrainsMono Nerd Font SemiBold 15"/font: "JetBrainsMono Nerd Font SemiBold 13"/' "$rofi_config_file" 2>&1 | tee -a "$LOG"
  fi
fi

printf "\n%.0s" {1..1}
prompt_clock_12h "$LOG"
printf "\n%.0s" {1..1}
prompt_rainbow_borders "$LOG"
printf "\n%.0s" {1..1}
prompt_express_upgrade "$EXPRESS_SUPPORTED" "$LOG"

set -e

# Check if the ~/.config/ directory exists
if [ ! -d "$HOME/.config" ]; then
  echo "${ERROR} - $HOME/.config directory does not exist. Creating it now."
  mkdir -p "$HOME/.config" && echo "Directory created successfully." || echo "Failed to create directory."
fi

printf "${INFO} - copia dotfiles ${SKY_BLUE}prima${RESET} parte\n"
copy_phase1 "$LOG"
printf "\n%.0s" {1..1}
copy_waybar "$LOG"
printf "\n%.0s" {1..1}
printf "${INFO} - Copia dotfiles ${SKY_BLUE}seconda${RESET} parte\n"
copy_phase2 "$LOG"
printf "\\n%.0s" {1..1}

# ags config
# Check if ags is installed
if command -v ags >/dev/null 2>&1; then
  echo -e "${NOTE} - ${YELLOW}ags${RESET} è rilevato come installato"

  DIRPATH_AGS="$HOME/.config/ags"

  if [ ! -d "$DIRPATH_AGS" ]; then
    echo "${INFO} - Configurazione ags non trovata, copio nuova configurazione."
    if [ -d "config/ags" ]; then
      cp -r "config/ags/" "$DIRPATH_AGS" 2>&1 | tee -a "$LOG"
    fi
  else
    read -p "${CAT} Vuoi sovrascrivere la configurazione ${YELLOW}ags${RESET} esistente? [s/N] " answer_ags
    case "$answer_ags" in
    [YySs]*)
      BACKUP_DIR=$(get_backup_dirname)
      mv "$DIRPATH_AGS" "$DIRPATH_AGS-backup-$BACKUP_DIR" 2>&1 | tee -a "$LOG"
      echo -e "${NOTE} - Backup della configurazione ags in $DIRPATH_AGS-backup-$BACKUP_DIR"

      if cp -r "config/ags/" "$DIRPATH_AGS" 2>&1 | tee -a "$LOG"; then
        echo "${OK} - Configurazione ${YELLOW}ags${RESET} sovrascritta con successo."
      else
        echo "${ERROR} - Copia della configurazione ${YELLOW}ags${RESET} fallita."
        exit 1
      fi
      ;;
    *)
      echo "${NOTE} - Salto la sovrascrittura della configurazione ags."
      ;;
    esac
  fi
fi

printf "\\n%.0s" {1..1}

# Capture installed dotfiles version at the start of the workflow so we
# can apply cleanup rules based on the pre-upgrade state, even if a newer
# version marker is copied in later.
INSTALLED_VERSION_AT_START="$(get_installed_dotfiles_version || true)"

# quickshell (ags alternative)
# Check if quickshell is installed
if command -v qs >/dev/null 2>&1; then
  echo -e "${NOTE} - ${YELLOW}quickshell${RESET} è rilevato come installato"

  DIRPATH_QS="$HOME/.config/quickshell"

  if [ ! -d "$DIRPATH_QS" ]; then
    echo "${INFO} - Configurazione quickshell non trovata, copio nuova configurazione."
    if [ -d "config/quickshell" ]; then
      cp -r "config/quickshell/" "$DIRPATH_QS" 2>&1 | tee -a "$LOG"
    fi
  else
    # If default shell.qml exists, it blocks named config subdirectory detection
    # Remove it to enable the overview config to be found
    if [ -f "$DIRPATH_QS/shell.qml" ]; then
      echo "${NOTE} - Rimozione shell.qml predefinito per abilitare il rilevamento configurazione quickshell" 2>&1 | tee -a "$LOG"
      rm "$DIRPATH_QS/shell.qml"
    fi

    read -p "${CAT} Vuoi sovrascrivere la configurazione ${YELLOW}quickshell${RESET} esistente? [s/N] " answer_qs
    case "$answer_qs" in
    [YySs]*)
      BACKUP_DIR=$(get_backup_dirname)
      mv "$DIRPATH_QS" "$DIRPATH_QS-backup-$BACKUP_DIR" 2>&1 | tee -a "$LOG"
      echo -e "${NOTE} - Backup di quickshell in $DIRPATH_QS-backup-$BACKUP_DIR"

      cp -r "config/quickshell/" "$DIRPATH_QS" 2>&1 | tee -a "$LOG"
      if [ $? -eq 0 ]; then
        echo "${OK} - ${YELLOW}quickshell${RESET} sovrascritto con successo."
        # Remove default shell.qml from new copy to enable overview detection
        rm -f "$DIRPATH_QS/shell.qml" 2>&1 | tee -a "$LOG"
      else
        echo "${ERROR} - Copia della configurazione ${YELLOW}quickshell${RESET} fallita."
        exit 1
      fi
      ;;
    *)
      echo "${NOTE} - Salto la sovrascrittura della configurazione quickshell."
      ;;
    esac
  fi

  # Ensure overview subdirectory exists and is up to date
  DIRPATH_OVERVIEW="$DIRPATH_QS/overview"
  if [ ! -d "$DIRPATH_OVERVIEW" ] && [ -d "config/quickshell/overview" ]; then
    echo "${INFO} - Copia configurazione quickshell overview..." 2>&1 | tee -a "$LOG"
    cp -r "config/quickshell/overview" "$DIRPATH_QS/" 2>&1 | tee -a "$LOG"
    echo "${OK} - Configurazione quickshell overview copiata con successo" 2>&1 | tee -a "$LOG"
  fi

  # Check for old quickshell startup commands and update them
  HYPR_STARTUP="$HOME/.config/hypr/configs/Startup_Apps.conf"
  if [ -f "$HYPR_STARTUP" ]; then
    if grep -q '^exec-once = qs\s*$\|^exec-once = qs &' "$HYPR_STARTUP"; then
      echo "${NOTE} - Trovato vecchio comando avvio Quickshell, aggiornamento alla nuova configurazione overview..." 2>&1 | tee -a "$LOG"
      # Replace old 'qs' or 'qs &' with new 'qs -c overview'
      sed -i 's/^\(\s*\)exec-once = qs\s*$/\1exec-once = qs -c overview  # Quickshell Overview/' "$HYPR_STARTUP" 2>&1 | tee -a "$LOG"
      sed -i 's/^\(\s*\)exec-once = qs &$/\1exec-once = qs -c overview  # Quickshell Overview/' "$HYPR_STARTUP" 2>&1 | tee -a "$LOG"
      echo "${OK} - Comando avvio Quickshell aggiornato alla configurazione overview" 2>&1 | tee -a "$LOG"
    fi
  fi
fi
printf "\n%.0s" {1..1}

restore_hypr_assets "$LOG" "$EXPRESS_MODE"
printf "\\n%.0s" {1..1}

restore_user_configs "$LOG" "$EXPRESS_MODE" "$INSTALLED_VERSION_AT_START"
printf "\\n%.0s" {1..1}

restore_user_scripts "$LOG" "$EXPRESS_MODE"
printf "\n%.0s" {1..1}

restore_hypr_files "$LOG" "$EXPRESS_MODE"
printf "\n%.0s" {1..1}

# Abilita bordi animati se richiesto
if [ "${RAINBOW_BORDERS_ENABLED:-false}" = true ]; then
  RBBAK="$HOME/.config/hypr/UserScripts/RainbowBorders.bak.sh"
  RBTGT="$HOME/.config/hypr/UserScripts/RainbowBorders.sh"
  if [ -f "$RBBAK" ]; then
    mv "$RBBAK" "$RBTGT" 2>&1 | tee -a "$LOG"
    echo "${OK} Bordi animati abilitati." 2>&1 | tee -a "$LOG"
  fi
  SA_CONF="$HOME/.config/hypr/configs/Startup_Apps.conf"
  if [ -f "$SA_CONF" ]; then
    sed -i 's|^#exec-once = \$UserScripts/RainbowBorders.sh|exec-once = $UserScripts/RainbowBorders.sh|' "$SA_CONF"
    echo "${OK} exec-once RainbowBorders.sh abilitato in Startup_Apps.conf." 2>&1 | tee -a "$LOG"
  fi
fi
printf "\n%.0s" {1..1}

# Define the target directory for rofi themes
rofi_DIR="$HOME/.local/share/rofi/themes"

if [ ! -d "$rofi_DIR" ]; then
  mkdir -p "$rofi_DIR"
fi
if [ -d "$HOME/.config/rofi/themes" ]; then
  if [ -z "$(ls -A $HOME/.config/rofi/themes)" ]; then
    echo '/* Dummy Rofi theme */' >"$HOME/.config/rofi/themes/dummy.rasi"
  fi
  ln -snf "$HOME/.config/rofi/themes/"* "$HOME/.local/share/rofi/themes/"
  # Delete the dummy file if it was created
  if [ -f "$HOME/.config/rofi/themes/dummy.rasi" ]; then
    rm "$HOME/.config/rofi/themes/dummy.rasi"
  fi
fi

printf "\n%.0s" {1..1}

# wallpaper stuff
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
mkdir -p "$PICTURES_DIR/wallpapers"
if cp -r wallpapers "$PICTURES_DIR/"; then
  echo "${OK} Some ${MAGENTA}wallpapers${RESET} copied successfully!" | tee -a "$LOG"
else
  echo "${ERROR} Failed to copy some ${YELLOW}wallpapers${RESET}" | tee -a "$LOG"
fi

# Install desktop entries
mkdir -p "$HOME/.local/share/applications"
if [ -d "local/share/applications" ]; then
  cp local/share/applications/*.desktop "$HOME/.local/share/applications/" 2>&1 | tee -a "$LOG"
  sed -i "s|/home/tanarox/|$HOME/|g" "$HOME/.local/share/applications/"*.desktop 2>/dev/null || true
  echo "${OK} File .desktop installati in ~/.local/share/applications/" | tee -a "$LOG"
fi

# Installa helper privilegiato per la GUI tema SDDM
if [ -f "local/bin/sddm-theme-apply" ]; then
  sudo cp "local/bin/sddm-theme-apply" /usr/local/bin/sddm-theme-apply
  sudo chmod +x /usr/local/bin/sddm-theme-apply
  echo "${OK} sddm-theme-apply installato in /usr/local/bin/" | tee -a "$LOG"
fi

# Installa helper privilegiato per la configurazione PAM biometrica
if [ -f "local/bin/biometrics-pam-apply" ]; then
  sudo cp "local/bin/biometrics-pam-apply" /usr/local/bin/biometrics-pam-apply
  sudo chmod +x /usr/local/bin/biometrics-pam-apply
  echo "${OK} biometrics-pam-apply installato in /usr/local/bin/" | tee -a "$LOG"
fi

# Patch Howdy (riconoscimento facciale) sui temi SDDM installati
printf "\n%.0s" {1..1}
echo "${NOTE} Applicazione patch Howdy ai temi SDDM..." | tee -a "$LOG"
HOWDY_TIMER='
    Timer {
        id: autoFaceLogin
        interval: 50
        running: true
        repeat: false
        onTriggered: {
            var user = config.AllowUppercaseLettersInUsernames == "false" ? username.text.toLowerCase() : username.text
            sddm.login(user, "", sessionSelect.selectedSession)
        }
    }'

_patch_qml() {
  local file="$1" marker="$2" timer="$3"
  if [ -f "$file" ] && ! grep -q "autoFaceLogin" "$file"; then
    sudo python3 -c "
import sys
path='$file'
timer='''$timer'''
with open(path) as f: c=f.read()
c=c.rstrip()
c=c[:-1].rstrip()+'\n'+timer+'\n}\n'
with open(path,'w') as f: f.write(c)
" && echo "${OK} Howdy applicato: $file" | tee -a "$LOG"
  fi
}

# sugar-candy
_patch_qml "/usr/share/sddm/themes/sugar-candy/Components/Input.qml" "resetError" "$HOWDY_TIMER"

# sddm-astronaut-theme
_patch_qml "/usr/share/sddm/themes/sddm-astronaut-theme/Components/Input.qml" "resetError" "$HOWDY_TIMER"

# elarun
sudo python3 -c "
path='/usr/share/sddm/themes/elarun/Main.qml'
import os;
if os.path.exists(path):
    with open(path) as f: c=f.read()
    if 'autoFaceLogin' not in c:
        t='''\n    Timer {\n        id: autoFaceLogin\n        interval: 50\n        running: true\n        repeat: false\n        onTriggered: sddm.login(user_entry.text, \"\", sessionIndex)\n    }\n'''
        c=c.rstrip(); c=c[:-1].rstrip()+'\n'+t+'}\n'
        with open(path,'w') as f: f.write(c)
        print('elarun OK')
" 2>&1 | tee -a "$LOG"

# maldives
sudo python3 -c "
path='/usr/share/sddm/themes/maldives/Main.qml'
import os
if os.path.exists(path):
    with open(path) as f: c=f.read()
    if 'autoFaceLogin' not in c:
        t='''\n    Timer {\n        id: autoFaceLogin\n        interval: 50\n        running: true\n        repeat: false\n        onTriggered: sddm.login(name.text, \"\", sessionIndex)\n    }\n'''
        c=c.rstrip(); c=c[:-1].rstrip()+'\n'+t+'}\n'
        with open(path,'w') as f: f.write(c)
        print('maldives OK')
" 2>&1 | tee -a "$LOG"

# maya
sudo python3 -c "
path='/usr/share/sddm/themes/maya/Main.qml'
import os
if os.path.exists(path):
    with open(path) as f: c=f.read()
    if 'autoFaceLogin' not in c:
        t='''\n  Timer {\n    id: autoFaceLogin\n    interval: 50\n    running: true\n    repeat: false\n    onTriggered: sddm.login(maya_username.text, \"\", maya_session.index)\n  }\n'''
        c=c.rstrip(); c=c[:-1].rstrip()+'\n'+t+'}\n'
        with open(path,'w') as f: f.write(c)
        print('maya OK')
" 2>&1 | tee -a "$LOG"

# Genera miniature per la GUI SDDM
PREV_DIR="$HOME/.cache/sddm-theme-previews"
mkdir -p "$PREV_DIR"
if command -v magick >/dev/null 2>&1; then
  echo "${NOTE} Generazione miniature temi SDDM..." | tee -a "$LOG"
  _thumb() { [ -f "$1" ] && magick "$1" -resize 180x101^ -gravity center -extent 180x101 "$2" 2>/dev/null; }
  _thumb /usr/share/sddm/themes/elarun/elarun.jpg                          "$PREV_DIR/elarun.png"
  _thumb /usr/share/sddm/themes/maldives/maldives.jpg                      "$PREV_DIR/maldives.png"
  _thumb /usr/share/sddm/themes/maya/screenshots/hi_IN.png                 "$PREV_DIR/maya.png"
  _thumb /usr/share/sddm/themes/simple_sddm_2/Backgrounds/default          "$PREV_DIR/simple_sddm_2.png"
  _thumb /usr/share/sddm/themes/sugar-candy/Backgrounds/Mountain.jpg       "$PREV_DIR/sugar-candy.png"
  ADIR=/usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds
  _thumb "$ADIR/astronaut.png"              "$PREV_DIR/astronaut.png"
  _thumb "$ADIR/black_hole.png"            "$PREV_DIR/black_hole.png"
  _thumb "$ADIR/cyberpunk.png"             "$PREV_DIR/cyberpunk.png"
  _thumb "$ADIR/hyprland_kath.png"         "$PREV_DIR/hyprland_kath.png"
  _thumb "$ADIR/hyprland_kath.png"         "$PREV_DIR/hyprland_kath_static.png"
  _thumb "$ADIR/jake_the_dog.png"          "$PREV_DIR/jake_the_dog.png"
  _thumb "$ADIR/jake_the_dog.png"          "$PREV_DIR/jake_the_dog_static.png"
  _thumb "$ADIR/japanese_aesthetic.png"    "$PREV_DIR/japanese_aesthetic.png"
  _thumb "$ADIR/pixel_sakura_static.png"   "$PREV_DIR/pixel_sakura.png"
  _thumb "$ADIR/pixel_sakura_static.png"   "$PREV_DIR/pixel_sakura_static.png"
  _thumb "$ADIR/post-apocalyptic_hacker.png" "$PREV_DIR/post-apocalyptic_hacker.png"
  _thumb "$ADIR/purple_leaves.png"         "$PREV_DIR/purple_leaves.png"
  echo "${OK} Miniature temi SDDM generate." | tee -a "$LOG"
fi

# Set some files as executable
chmod +x "$HOME/.config/hypr/scripts/"* 2>&1 | tee -a "$LOG"
chmod +x "$HOME/.config/hypr/UserScripts/"* 2>&1 | tee -a "$LOG"
# Set executable for initial-boot.sh
chmod +x "$HOME/.config/hypr/initial-boot.sh" 2>&1 | tee -a "$LOG"

# Download voce italiana Piper (Paola) per saluto vocale all'avvio
PIPER_DIR="$HOME/.local/share/piper"
PIPER_MODEL="$PIPER_DIR/it_IT-paola-medium.onnx"
if command -v piper-tts >/dev/null 2>&1; then
  if [ ! -f "$PIPER_MODEL" ]; then
    echo "${INFO} Download voce italiana Piper (Paola)..." 2>&1 | tee -a "$LOG"
    mkdir -p "$PIPER_DIR"
    BASE_URL="https://huggingface.co/rhasspy/piper-voices/resolve/main/it/it_IT/paola/medium"
    if curl -L "$BASE_URL/it_IT-paola-medium.onnx" -o "$PIPER_MODEL" 2>&1 | tee -a "$LOG" && \
       curl -L "$BASE_URL/it_IT-paola-medium.onnx.json" -o "$PIPER_MODEL.json" 2>&1 | tee -a "$LOG"; then
      echo "${OK} Voce Piper (Paola) scaricata con successo." | tee -a "$LOG"
    else
      echo "${ERROR} Download voce Piper fallito." | tee -a "$LOG"
    fi
  else
    echo "${NOTE} Voce Piper (Paola) già presente, salto il download." | tee -a "$LOG"
  fi
else
  echo "${WARN} piper-tts non installato, salto il download della voce." | tee -a "$LOG"
fi

chassis_type=$(detect_waybar_config)
if [ "$chassis_type" = "desktop" ]; then
  config_file="$waybar_config"
  config_remove=" Laptop"
else
  config_file="$waybar_config_laptop"
  config_remove=""
fi

# Check if ~/.config/waybar/config does not exist or is a symlink
if [ ! -e "$HOME/.config/waybar/config" ] || [ -L "$HOME/.config/waybar/config" ]; then
  ln -sf "$config_file" "$HOME/.config/waybar/config" 2>&1 | tee -a "$LOG"
fi

# Remove inappropriate waybar configs
rm -rf "$HOME/.config/waybar/configs/[TOP] Default$config_remove" \
  "$HOME/.config/waybar/configs/[BOT] Default$config_remove" \
  "$HOME/.config/waybar/configs/[TOP] Default$config_remove (old v1)" \
  "$HOME/.config/waybar/configs/[TOP] Default$config_remove (old v2)" \
  "$HOME/.config/waybar/configs/[TOP] Default$config_remove (old v3)" \
  "$HOME/.config/waybar/configs/[TOP] Default$config_remove (old v4)" 2>&1 | tee -a "$LOG" || true

printf "\n%.0s" {1..1}

# for SDDM (simple_sddm_2)
sddm_simple_sddm_2="/usr/share/sddm/themes/simple_sddm_2"
if [ -d "$sddm_simple_sddm_2" ] && [ "$EXPRESS_MODE" -eq 1 ]; then
  echo "${NOTE} Modalità express: salto il prompt sfondo SDDM." 2>&1 | tee -a "$LOG"
elif [ -d "$sddm_simple_sddm_2" ]; then
  while true; do
    echo -n "${CAT} Tema SDDM simple_sddm_2 rilevato! Applicare lo sfondo attuale come sfondo SDDM? (s/n): "
    read SDDM_WALL

    # Remove any leading/trailing whitespace or newlines from input
    SDDM_WALL=$(echo "$SDDM_WALL" | tr -d '\n' | tr -d ' ')

    case $SDDM_WALL in
    [YySs])
      # Copy the wallpaper, ignore errors if the file exists or fails
      sudo -n cp -r "config/hypr/wallpaper_effects/.wallpaper_current" "/usr/share/sddm/themes/simple_sddm_2/Backgrounds/default" || true
      echo "${NOTE} Sfondo attuale applicato come sfondo SDDM predefinito" 2>&1 | tee -a "$LOG"
      break
      ;;
    [Nn])
      echo "${NOTE} Hai scelto di non applicare lo sfondo attuale all'SDDM." 2>&1 | tee -a "$LOG"
      break
      ;;
    *)
      echo "Inserisci 's' o 'n' per procedere."
      ;;
    esac
  done
fi

# additional wallpapers
printf "\n%.0s" {1..1}
echo "${MAGENTA}Di default vengono copiati solo pochi sfondi${RESET}..."

if [ "$EXPRESS_MODE" -eq 1 ]; then
  echo "${NOTE} Modalità express: salto il prompt download sfondi aggiuntivi." 2>&1 | tee -a "$LOG"
else
  while true; do
    echo "${NOTE} Alcuni di questi sfondi sono generati o migliorati con l'IA. Seleziona (N/n) se questo è un problema per te. "
    echo -n "${CAT} Vuoi scaricare sfondi aggiuntivi? ${WARN} Circa 1GB di dati (s/n): "
    read WALL

    case $WALL in
    [YySs])
      echo "${NOTE} Download sfondi aggiuntivi in corso..."
      rm -rf Wallpaper-Bank-Tarallo 2>/dev/null
      if git clone "https://github.com/kilian85/Wallpaper-Bank-Tarallo.git"; then
        echo "${OK} Sfondi scaricati con successo." 2>&1 | tee -a "$LOG"

        # Check if wallpapers directory exists and create it if not
        if [ ! -d "$PICTURES_DIR/wallpapers" ]; then
          mkdir -p "$PICTURES_DIR/wallpapers"
          echo "${OK} Cartella sfondi creata." 2>&1 | tee -a "$LOG"
        fi

        if cp -R Wallpaper-Bank-Tarallo/wallpapers/* "$PICTURES_DIR/wallpapers/" >>"$LOG" 2>&1; then
          echo "${OK} Sfondi copiati con successo." 2>&1 | tee -a "$LOG"
          rm -rf Wallpaper-Bank-Tarallo 2>&1
          break
        else
          echo "${ERROR} Copia degli sfondi fallita" 2>&1 | tee -a "$LOG"
        fi
      else
        echo "${ERROR} Download sfondi aggiuntivi fallito" 2>&1 | tee -a "$LOG"
      fi
      ;;
    [Nn])
      echo "${NOTE} Hai scelto di non scaricare sfondi aggiuntivi." 2>&1 | tee -a "$LOG"
      break
      ;;
    *)
      echo "Inserisci 's' o 'n' per procedere."
      ;;
    esac
  done
fi

# Execute the cleanup function
if [ "$EXPRESS_MODE" -eq 1 ]; then
  cleanup_backups auto "$LOG"
else
  cleanup_backups prompt "$LOG"
fi

# Check if ~/.config/waybar/style.css does not exist or is a symlink
if [ ! -e "$HOME/.config/waybar/style.css" ] || [ -L "$HOME/.config/waybar/style.css" ]; then
  ln -sf "$waybar_style" "$HOME/.config/waybar/style.css" 2>&1 | tee -a "$LOG"
fi

printf "\n%.0s" {1..1}

# initialize wallust to avoid config error on hyprland
wallust run -s $wallpaper 2>&1 | tee -a "$LOG"

printf "\n%.0s" {1..2}
printf "${OK} OTTIMO! I Dotfile Hyprland Tarallo sono stati caricati e sono pronti!!! "
printf "\n%.0s" {1..1}
printf "${INFO} Tuttavia, è ${MAGENTA}ALTAMENTE CONSIGLIATO${RESET} fare logout e rientrare o meglio riavviare per evitare problemi"
printf "\n%.0s" {1..1}
printf "${SKY_BLUE}Grazie${RESET} per aver usato la ${MAGENTA}Configurazione Hyprland Tarallo${RESET}... ${YELLOW}BUON DIVERTIMENTO!!!${RESET}"
printf "\n%.0s" {1..3}
