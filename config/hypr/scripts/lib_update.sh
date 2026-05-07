#!/usr/bin/env bash

# run_repo_update
# Arguments:
#   $1 - expected repository root (typically SCRIPT_DIR from copy.sh)
# Behavior:
#   * Verifies the script is executed from Hyprland-Dots root.
#   * Stashes local changes (including untracked), pulls latest changes.
#   * Shows progress, reports errors, and summarizes results.
#   * Waits for user input before returning control to caller.
run_repo_update() {
  local repo_dir="${1:-$(pwd)}"
  local expected_name="Hyprland-Dots"
  local log_dir="$repo_dir/Copy-Logs"
  local log_file="$log_dir/update-$(date +%d-%H%M%S)_git.log"

  mkdir -p "$log_dir"

  echo "${INFO} Avvio aggiornamento repository..." | tee -a "$log_file"

  if [ ! -d "$repo_dir" ] || [ "$(basename "$repo_dir")" != "$expected_name" ]; then
    echo "${ERROR} Questo script deve essere eseguito dalla directory $expected_name. Posizione attuale: $(pwd)" | tee -a "$log_file"
    read -n1 -s -r -p "Premi un tasto per tornare al menu..."
    echo
    return 1
  fi

  if [ "$PWD" != "$repo_dir" ]; then
    echo "${INFO} Cambio directory in $repo_dir" | tee -a "$log_file"
    cd "$repo_dir" || {
      echo "${ERROR} Impossibile cambiare directory in $repo_dir" | tee -a "$log_file"
      read -n1 -s -r -p "Premi un tasto per tornare al menu..."
      echo
      return 1
    }
  fi

  local head_before stash_msg pull_status=0
  head_before=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

  echo "${INFO} Controllo albero di lavoro..." | tee -a "$log_file"
  if git diff --quiet && git diff --cached --quiet; then
    stash_msg="Nessuna modifica locale; nessuno stash creato."
    echo "${NOTE} $stash_msg" | tee -a "$log_file"
  else
    echo "${INFO} Salvataggio modifiche locali (tracciate + non tracciate)..." | tee -a "$log_file"
    if stash_output=$(git stash push -u 2>&1); then
      stash_msg="Stash creato: $(echo "$stash_output" | head -n1)"
      echo "${OK} $stash_msg" | tee -a "$log_file"
    else
      echo "${ERROR} git stash fallito. Dettagli:" | tee -a "$log_file"
      echo "$stash_output" | tee -a "$log_file"
      read -n1 -s -r -p "Premi un tasto per tornare al menu..."
      echo
      return 1
    fi
  fi

  echo "${INFO} Download ultime modifiche..." | tee -a "$log_file"
  if git pull --ff-only 2>&1 | tee -a "$log_file"; then
    pull_status=0
    echo "${OK} Repository aggiornato con successo." | tee -a "$log_file"
  else
    pull_status=$?
    echo "${ERROR} git pull fallito (uscita $pull_status)." | tee -a "$log_file"
  fi

  local head_after
  head_after=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

  echo "----------------------------------------" | tee -a "$log_file"
  echo "Riepilogo:" | tee -a "$log_file"
  echo "  Repository  : $repo_dir" | tee -a "$log_file"
  echo "  HEAD prima  : $head_before" | tee -a "$log_file"
  echo "  HEAD dopo   : $head_after" | tee -a "$log_file"
  echo "  Stash       : $stash_msg" | tee -a "$log_file"
  echo "  Stato pull  : $( [ $pull_status -eq 0 ] && echo successo || echo fallito )" | tee -a "$log_file"
  echo "----------------------------------------" | tee -a "$log_file"

  # Also run the UserConfigs duplicate cleanup for existing installs,
  # using the same version gating as the main copy workflow (<= v2.3.19).
  if declare -f get_installed_dotfiles_version >/dev/null 2>&1 \
     && declare -f cleanup_duplicate_userconfigs >/dev/null 2>&1; then
    local installed_version
    installed_version=$(get_installed_dotfiles_version)
    if [ -n "$installed_version" ]; then
      echo "${INFO:-[INFO]} Controllo duplicati UserConfigs dopo aggiornamento repository (rilevata v$installed_version)..." | tee -a "$log_file"
      cleanup_duplicate_userconfigs "$installed_version" "$log_file"
    else
      echo "${NOTE:-[NOTE]} Salto pulizia duplicati UserConfigs; versione installata non rilevata." | tee -a "$log_file"
    fi
  fi

  read -n1 -s -r -p "Premi un tasto per tornare al menu principale..."
  echo

  return $pull_status
}
