# Shared configuration for obsidian-android-sync (source only, do not execute).

if [[ -n "${OBSIDIAN_SYNC_CONFIG_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi

_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="$(cd "$_CONFIG_DIR/.." && pwd)"
INSTALL_BIN="$_CONFIG_DIR"

export OBSIDIAN_SYNC_CONFIG_LOADED=1

export STORAGE_PATH="/storage/emulated/0"
export NOTIFICATION_PATH="$STORAGE_PATH/sync-error-notification"

mkdir -p "$STATE_DIR/tmp" "$STATE_DIR/git-repos" "$INSTALL_BIN"

export LOCK_FILE="$STATE_DIR/sync-vaults.lock"
export LOG_FILE="$STATE_DIR/sync.log"
export SYNC_TMP_DIR="$STATE_DIR/tmp"
export GIT_REPOS_PATH="$STATE_DIR/git-repos"

if [[ -f "$STATE_DIR/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$STATE_DIR/.env"
  set +a
fi

: "${SCRIPTS_REPO_PATH:=/storage/emulated/0/repos/obsidian-android-sync}"
: "${OBSIDIAN_DIR_PATH:=/storage/emulated/0/repos/Obsidian}"
export SCRIPTS_REPO_PATH OBSIDIAN_DIR_PATH

export RESET="\033[0m"
export GREEN="\033[1;32m"
export RED="\033[1;31m"
export BLUE="\033[1;34m"
export YELLOW="\033[1;33m"
