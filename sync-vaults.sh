#!/data/data/com.termux/files/usr/bin/bash
# shellcheck source=config.sh
source "$(dirname "$0")/config.sh"

# Function to remove lock file
cleanup() {
    rm -f "$LOCK_FILE"
    exit 1
}

trap cleanup INT TERM

wait_for_lock_release() {
    while [[ -e "$LOCK_FILE" ]]; do
        sleep 1
    done
}

if [[ -e "$LOCK_FILE" ]]; then
    if [[ -z "$(ps -p "$(cat "$LOCK_FILE")" -o pid= 2>/dev/null)" ]]; then
        echo "Removing stale lock file."
        rm -f "$LOCK_FILE"
    else
        wait_for_lock_release
    fi
fi

echo $$ > "$LOCK_FILE"

skip_pause_val="--skip-pause"

# shellcheck source=log_helper.sh
source "$(dirname "$0")/log_helper.sh"
setup_logging "$LOG_FILE"

temp_dir="$SYNC_TMP_DIR/sync_$$"
mkdir -p "$temp_dir"

GIT_SYNC="$(dirname "$0")/git-sync"

cmd () {
  printf "\n\033[0;34m%s\033[0m\n" "$(basename "$PWD")"
  "$GIT_SYNC" -ns 2>&1
  if [[ $? -ne 0 ]]; then
    cat "$1" >> "$NOTIFICATION_PATH"
  fi
}

git_repos=()

for dir in "$OBSIDIAN_DIR_PATH"/*; do
  if [[ -d "$dir" ]]; then
    cd "$dir"
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
      git_repos+=("$dir")
    fi
  fi
done

msg="You can try running setup ($INSTALL_BIN/setup) to see if it helps."

if [[ ${#git_repos[@]} -eq 0 ]]; then
  echo -e "${YELLOW}No Git repositories found in the Obsidian folder.\n${msg}${RESET}"
  exit 1
fi

if [[ -n "$1" && "$1" != "$skip_pause_val" ]]; then
  if [[ " ${git_repos[*]} " == *" $OBSIDIAN_DIR_PATH/$1 "* ]]; then
    repo="$OBSIDIAN_DIR_PATH/$1"
    repo_name="$(basename "$repo")"
    tmp_log="$temp_dir/${repo_name}.log"
    (cd "$repo" && cmd "$tmp_log" > "$tmp_log" 2>&1)
    cat "$tmp_log" >> "$LOG_FILE"
  else
    echo -e "${RED}Specified directory doesn't exist or is not a Git repository.\n${msg}${RESET}"
    rm -f "$LOCK_FILE"
    exit 1
  fi
else
  pids=()
  for repo in "${git_repos[@]}"; do
    repo_name="$(basename "$repo")"
    tmp_log="$temp_dir/${repo_name}.log"

    (
      cd "$repo" && cmd "$tmp_log" > "$tmp_log" 2>&1
    ) &
    pids+=($!)
  done

  for pid in "${pids[@]}"; do
    wait "$pid"
  done

  cat "$temp_dir"/*.log >> "$LOG_FILE" 2>/dev/null || true
fi

rm -rf "$temp_dir"

log_cleanup "$LOG_FILE"

if [[ -z "$1" ]]; then
  bypass_log "echo -e '\n\033[44;97mPress enter to finish...\033[0m' && read none"
fi

rm -f "$LOCK_FILE"
exit 0
