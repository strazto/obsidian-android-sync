# Obsidian Android Sync
Easily sync your Obsidian vaults on Android using Git (SSH) + Termux, with automation and shortcuts using Tasker.
It works by syncing a vault when the Obsidian app is opened (or brought up from recents) and when it's closed (or if you just switch to another app).

The sync is done using the excellent [git-sync script by simonthum](https://github.com/simonthum/git-sync). I made a slight change to it so there's a copy of it being used here.

To prevent conflicts, I recommend you add the following lines to your .gitignore file in all your vaults that you'll be syncing using Git. If you notice a plugin has a file which is often in conflict, you'll want to add that as well (remember to un-track these files first with `git rm --cached <file>`):
```gitignore
/.obsidian/workspace.json
/.obsidian/workspace-mobile.json
/.obsidian/plugins/obsidian-git/data.json
/conflict-files-obsidian-git.md
```
To stop conflicts from happening with your note files, you can create a `.gitattributes` file in the root of your vaults with the following content. It will basically always accept both changes for `.md` files.
```gitattributes
*.md merge=union
```

## Install layout

All app state and scripts live under a fixed directory (not configurable — Tasker paths depend on it):

```text
~/.obsidian_android_sync_state/
  .env                 # your paths (see .env.example)
  sync.log
  sync-vaults.lock
  tmp/
  git-repos/           # bare git objects after worktree-fix
  bin/                 # installed scripts (run setup to populate)
```

Configure vault and script-repo locations in `~/.obsidian_android_sync_state/.env`:

- `SCRIPTS_REPO_PATH` — git clone of this repository (any path)
- `OBSIDIAN_DIR_PATH` — folder where Obsidian opens vaults (worktree checkouts)

These paths are independent; they do not need to share a parent directory.

## Termux Setup (fresh install)

1. Install [F-Droid](https://f-droid.org/en/).
2. Install [Termux](https://f-droid.org/en/packages/com.termux/), [Termux:Tasker](https://f-droid.org/en/packages/com.termux.tasker/), and [Termux:API](https://f-droid.org/en/packages/com.termux.api/) from F-Droid (NOT from the Play Store).

   The next steps are run in Termux.
3. Run `termux-setup-storage` and grant file access.
4. Run `pkg update && pkg upgrade -y && pkg install -y git openssh termux-api`.
5. Clone this repo anywhere (example path):

   ```bash
   git clone https://github.com/DovieW/obsidian-android-sync.git \
     ~/storage/shared/repos/obsidian-android-sync
   ```

6. Edit paths if needed, then run setup from the clone:

   ```bash
   bash ~/storage/shared/repos/obsidian-android-sync/setup
   ```

   Setup installs scripts to `~/.obsidian_android_sync_state/bin/`, seeds `.env` from `.env.example` if missing, checks storage access, and enables `allow-external-apps` in `~/.termux/termux.properties` (idempotent).

7. **SSH key** (manual — not done by setup):

   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
   cat ~/.ssh/id_ed25519.pub   # add to GitHub/GitLab SSH keys
   ssh -T git@github.com       # optional test
   ```

   For older guides using RSA: `ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ""`.

8. Optional git settings (manual):

   ```bash
   git config --global --add safe.directory '*'
   git config --global core.editor nano
   git config --global merge.conflictstyle diff3
   ```

9. Create your vault parent folder if it does not exist, then clone vaults into `OBSIDIAN_DIR_PATH` (default `/storage/emulated/0/repos/Obsidian`). Avoid special characters in vault names if using Tasker.

10. Run worktree-fix once (fixes [Git corruption on shared storage](https://github.com/DovieW/obsidian-android-sync/issues/7)):

    ```bash
    ~/.obsidian_android_sync_state/bin/worktree-fix.sh
    ```

11. Sync manually:

    ```bash
    ~/.obsidian_android_sync_state/bin/sync-vaults.sh --skip-pause
    ```

    Optional shell aliases: add `source ~/.obsidian_android_sync_state/bin/env.sh` to your own `~/.bashrc` (not created by setup).

## Upgrade from old install

If you previously copied scripts into `$HOME` and used the old setup:

1. Pull this repo and run `bash /path/to/obsidian-android-sync/setup`
2. Run `~/.obsidian_android_sync_state/bin/migrate-from-legacy.sh` (`--dry-run` first optional)
3. Re-import [Obsidian_Syncing.prj.xml](Obsidian_Syncing.prj.xml) into Tasker (paths now point at `bin/`)

## Tasker Setup

1. Install [Tasker](https://play.google.com/store/apps/details?id=net.dinglisch.android.taskerm).
2. Enable the Termux permission for Tasker.
3. Open Obsidian and add vaults from `OBSIDIAN_DIR_PATH`.
4. Disable the [Obsidian Git plugin](https://github.com/Vinzent03/obsidian-git) on this device if you use it elsewhere.
5. Import the Tasker project from [TaskerNet](https://taskernet.com/shares/?user=AS35m8n3cQwLQVpqM%2Fik6LZsANJ%2F8SkOXbatTM3JXxEQY4KYaxES06TbTgTRcO7ziHKZXfzQKT1B&id=Project%3AObsidian+Syncing) or from `Obsidian_Syncing.prj.xml` in this repo.
6. Give Termux “Display over other apps” permission.
7. Add Tasker widgets for vault launchers and helpers (sync, status, log).

Tasker runs executables under:

`/data/data/com.termux/files/home/.obsidian_android_sync_state/bin/`

Sync error notifications watch `sync-error-notification` on shared storage (`/storage/emulated/0/`).

## Notes

- Re-run `~/.obsidian_android_sync_state/bin/setup` to pull script updates from `SCRIPTS_REPO_PATH`.
- Sync log: `~/.obsidian_android_sync_state/sync.log` (view with `list-log.sh`).
- Failed syncs append to the notification file on shared storage ([issue #3](https://github.com/DovieW/obsidian-android-sync/issues/3) — AutoNotification).
