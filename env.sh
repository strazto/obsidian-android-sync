# Optional interactive shell helpers (source manually, e.g. from ~/.bashrc).

INSTALL_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$INSTALL_BIN/config.sh"

alias ll="ls -lAFt --color=auto"
alias ls="ls -F --color=auto"
alias l="ls -1AFt --color=auto"
alias g="git"
alias n="nano"

alias sync="$INSTALL_BIN/sync-vaults.sh --skip-pause"
alias vaults="cd $OBSIDIAN_DIR_PATH"
alias storage="cd $STORAGE_PATH"
alias csetup="bash $INSTALL_BIN/setup"
