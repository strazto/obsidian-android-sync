#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# shellcheck source=config.sh
source "$(dirname "$0")/config.sh"

echo -e "${YELLOW}Creating destination directory at $GIT_REPOS_PATH if it doesn't exist...${RESET}"
mkdir -p "$GIT_REPOS_PATH"

for repo in "$OBSIDIAN_DIR_PATH"/*; do
  if [[ -d "$repo/.git" ]]; then

    if [[ -f "$repo/.git" ]]; then
      echo "$repo is a worktree. Skipping."
      continue
    fi

    repo_name=$(basename "$repo")

    echo -e "${YELLOW}Moving repository $repo_name to $GIT_REPOS_PATH...${RESET}"
    mv "$repo" "$GIT_REPOS_PATH/"

    echo -e "${YELLOW}Changing to the repository directory $GIT_REPOS_PATH/$repo_name...${RESET}"
    cd "$GIT_REPOS_PATH/$repo_name" || exit

    current_branch=$(git rev-parse --abbrev-ref HEAD)

    git switch -c empty
    git add -A
    git commit --allow-empty --message "delete"

    echo -e "${YELLOW}Removing all files from the working directory of $repo_name except the .git directory...${RESET}"
    find . -mindepth 1 \( -not -path "./.git" -a -not -path "./.git/*" \) -exec rm -rf {} +

    echo -e "${YELLOW}Creating a worktree for $repo_name back to $OBSIDIAN_DIR_PATH/$repo_name on $current_branch...${RESET}"
    mkdir -p "$OBSIDIAN_DIR_PATH/$repo_name"
    git worktree add "$OBSIDIAN_DIR_PATH/$repo_name" "$current_branch"
  fi
done

echo -e "${GREEN}All repositories have been moved and worktrees created.${RESET}"
