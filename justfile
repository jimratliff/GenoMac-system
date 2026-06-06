# For syntax/behavior of just, see https://github.com/casey/just

# Set default shell for just to Zsh
set shell := ["zsh", "-c"]

# use `just --choose` to be presented with an interactive chooser to select the particular recipe

# Typing only 'just' will run this default recipe, displaying interactive chooser.
default:
	@just --choose

############### Hypervisor

run-hypervisor:
    zsh scripts/run_hypervisor.sh

# Open the most-recent log file
# The most-recently created log file is alphabetically last (because time-stamped)
open-log:
	logs=("$GM_LOGS_DIRECTORY"/*(.N))
  (( ${#logs[@]} )) || { print -u2 -- "No log files found in $GM_LOGS_DIRECTORY"; exit 1; }
  open "${logs[-1]}"

############### Repo-specific configuration
genomac_local_dir := env_var('HOME') / '.genomac-system'
genomac_remote_repo := 'GenoMac-system'
genomac_github_owner := 'jimratliff'

genomac_fetch_url := 'https://github.com/' + genomac_github_owner + '/' + genomac_remote_repo + '.git'
genomac_push_url := 'git@github.com:' + genomac_github_owner + '/' + genomac_remote_repo + '.git'

############### Repo management

# Pull latest changes from origin/main, including any submodule updates. Does not require authenticating with GitHub
refresh-repo-and-module:
    git -C "{{genomac_local_dir}}" pull --recurse-submodules origin main

# Destructively make the local clone match origin/main.
# This discards local commits and tracked-file changes.
# It does not remove untracked files.
conform-local-to-remote:
    git -C "{{genomac_local_dir}}" fetch origin main
    git -C "{{genomac_local_dir}}" reset --hard origin/main
    git -C "{{genomac_local_dir}}" submodule sync --recursive
    git -C "{{genomac_local_dir}}" submodule update --init --recursive

# Below this point, the ability to authenticate with GitHub is required

# Updates this repo, including genomac-shared submodule, and pushes it back to GitHub
# The git diff check detects whether there are staged changes to the submodule and, if so, commits them.
# Requires authenticating with GitHub (hence the 'dev-' prefix to distinguish from refresh-repo-and-module recipe).
dev-update-repo-and-submodule:
    git -C "{{genomac_local_dir}}" pull --recurse-submodules origin main
    git -C "{{genomac_local_dir}}" submodule update --remote
    git -C "{{genomac_local_dir}}" add external/genomac-shared
    git -C "{{genomac_local_dir}}" diff --cached --quiet external/genomac-shared || git -C "{{genomac_local_dir}}" commit -m "Update genomac-shared submodule"
    git -C "{{genomac_local_dir}}" push origin main

# Configure remote for HTTPS fetch and SSH push
# Sets the fetch URL to HTTPS
# Sets the push URL to SSH, using the 1Password SSH agent
dev-configure-remote-for-https-fetch-and-ssh-push:
    git -C "{{genomac_local_dir}}" remote set-url origin "{{genomac_fetch_url}}"
    git -C "{{genomac_local_dir}}" remote set-url --push origin "{{genomac_push_url}}"
    git -C "{{genomac_local_dir}}" config pull.rebase false


############### System state utilities

system-states command:
    zsh scripts/utilities/system_state_utilities.sh '{{command}}'

system-states-show:
    just system-states show

system-states-clear-session-states:
    just system-states clear-session

system-states-clear-all-states:
    just system-states clear-all

############### Spawn-related commands

spawn-related command:
    zsh scripts/spawn/spawn-related-commands.sh '{{command}}'

spawn-related-test-parent-of-home-directories-from-volume:
	just spawn-related test-home-directories-parent

spawn-related-does-user-exist:
	just spawn-related test-user-exists

spawn-related-what-is-startup-container:
	just spawn-related what-is-startup-container

spawn-related-ensure-volume-exists:
	just spawn-related ensure-volume-exists

spawn-related-create-user:
	just spawn-related add-user
