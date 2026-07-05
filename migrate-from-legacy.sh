#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# shellcheck source=config.sh
source "$(dirname "$0")/config.sh"

DRY_RUN=false
ASSUME_YES=false

usage() {
  echo "Usage: $(basename "$0") [--dry-run] [--yes]"
  echo "Migrate from old install (scripts/log in \$HOME) to STATE_DIR layout."
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --yes) ASSUME_YES=true ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown option: $1" >&2; usage 1 ;;
  esac
  shift
done

run() {
  if $DRY_RUN; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

confirm() {
  $ASSUME_YES && return 0
  $DRY_RUN && return 0
  read -r -p "$1 [y/N] " ans
  [[ "$ans" == [yY] || "$ans" == [yY][eE][sS] ]]
}

actions=0

move_if_missing() {
  local src=$1 dest=$2 label=$3
  if [[ ! -e "$src" ]]; then
    return
  fi
  if [[ -e "$dest" ]]; then
    echo "Skip $label: destination already exists ($dest)"
    return
  fi
  actions=$((actions + 1))
  echo "Move $label: $src -> $dest"
  run mkdir -p "$(dirname "$dest")"
  run mv "$src" "$dest"
}

remove_legacy() {
  local path=$1
  if [[ -e "$path" || -L "$path" ]]; then
    actions=$((actions + 1))
    echo "Remove legacy: $path"
    run rm -f "$path"
  fi
}

move_if_missing "$HOME/sync.log" "$LOG_FILE" "sync log"
move_if_missing "$HOME/sync-vaults.lock" "$LOCK_FILE" "lock file"

if [[ -d "$HOME/repos/Obsidian" ]]; then
  if [[ -n "$(ls -A "$GIT_REPOS_PATH" 2>/dev/null || true)" ]]; then
    echo "Skip git repos move: $GIT_REPOS_PATH is not empty"
  else
    actions=$((actions + 1))
    echo "Move git repos: $HOME/repos/Obsidian/* -> $GIT_REPOS_PATH/"
    echo "${YELLOW}If vault worktrees break, re-run worktree-fix.sh after verifying OBSIDIAN_DIR_PATH.${RESET}"
    run mkdir -p "$GIT_REPOS_PATH"
    for item in "$HOME/repos/Obsidian"/*; do
      [[ -e "$item" ]] || continue
      run mv "$item" "$GIT_REPOS_PATH/"
    done
    if [[ -d "$HOME/repos/Obsidian" ]] && [[ -z "$(ls -A "$HOME/repos/Obsidian" 2>/dev/null || true)" ]]; then
      run rmdir "$HOME/repos/Obsidian" 2>/dev/null || true
    fi
  fi
fi

for name in sync-vaults.sh list-log.sh vaults-status.sh open-vault.sh git-sync worktree-fix.sh log_helper.sh config.sh env.sh setup; do
  remove_legacy "$HOME/$name"
done

for stale in "$HOME"/obsidian_sync_*; do
  [[ -e "$stale" ]] || continue
  actions=$((actions + 1))
  echo "Remove stale temp: $stale"
  run rm -rf "$stale"
done

BASHRC_FILE="/data/data/com.termux/files/usr/etc/bash.bashrc"
if [[ -f "$BASHRC_FILE" ]] && grep -q 'obsidian-sync-source-tag' "$BASHRC_FILE" 2>/dev/null; then
  actions=$((actions + 1))
  echo "Remove obsidian-sync-source-tag line from $BASHRC_FILE"
  if confirm "Remove injected bashrc source line?"; then
    if $DRY_RUN; then
      echo "[dry-run] sed -i '/obsidian-sync-source-tag/d' $BASHRC_FILE"
    else
      sed -i '/obsidian-sync-source-tag/d' "$BASHRC_FILE"
    fi
  else
    echo "Skipped bashrc cleanup"
  fi
fi

if [[ $actions -eq 0 ]]; then
  echo "${GREEN}Nothing to migrate.${RESET}"
else
  echo "${GREEN}Migration complete ($actions action(s)).${RESET}"
  echo "Re-import the Tasker project if you have not already."
fi
