# For syntax/behavior of just, see https://github.com/casey/just

# Set default shell for just to Zsh
set shell := ["zsh", "-c"]

# use `just --choose` to be presented with an interactive chooser to select the particular recipe

# Typing only 'just' will run this default recipe, displaying interactive chooser.
default:
	@just --choose

############### Run the Hypervisor

run-hypervisor:
    zsh scripts/run_hypervisor.sh

############### Repo-specific configuration
genomac_local_dir := env_var('HOME') / '.genomac-system'
genomac_remote_repo := 'GenoMac-system'
genomac_github_owner := 'jimratliff'

genomac_fetch_url := 'https://github.com/' + genomac_github_owner + '/' + genomac_remote_repo + '.git'
genomac_push_url := 'git@github.com:' + genomac_github_owner + '/' + genomac_remote_repo + '.git'

############### Repo management

# refresh-repo-and-module
# Refresh local checkout from origin/main, including submodules. Does not require GitHub authentication.
# WARNING: discards local changes in this managed checkout.

[group('Repo management WITHOUT GitHub authentication')]
refresh-repo-and-module:
    git -C "{{genomac_local_dir}}" fetch origin main
    git -C "{{genomac_local_dir}}" reset --hard origin/main
    git -C "{{genomac_local_dir}}" submodule update --init --recursive

# Destructively make the local clone match origin/main.
# This discards local commits and tracked-file changes.
# It does not remove untracked files.
[group('Repo management WITHOUT GitHub authentication')]
conform-local-to-remote:
    git -C "{{genomac_local_dir}}" fetch origin main
    git -C "{{genomac_local_dir}}" reset --hard origin/main
    git -C "{{genomac_local_dir}}" submodule sync --recursive
    git -C "{{genomac_local_dir}}" submodule update --init --recursive

# Below this point, the ability to authenticate with GitHub is required

# dev-update-repo-and-submodule
# Updates this repo, including genomac-shared submodule, and pushes it back to GitHub
# The git diff check detects whether there are staged changes to the submodule and, if so, commits them.
# Requires authenticating with GitHub (hence the 'dev-' prefix to distinguish from refresh-repo-and-module recipe).
[group('Repo management WITH GitHub authentication')]
dev-update-repo-and-submodule:
    git -C "{{genomac_local_dir}}" pull --recurse-submodules origin main
    git -C "{{genomac_local_dir}}" submodule update --remote
    git -C "{{genomac_local_dir}}" add external/genomac-shared
    git -C "{{genomac_local_dir}}" diff --cached --quiet external/genomac-shared || git -C "{{genomac_local_dir}}" commit -m "Update genomac-shared submodule"
    git -C "{{genomac_local_dir}}" push origin main

# Configure remote for HTTPS fetch and SSH push
# Sets the fetch URL to HTTPS
# Sets the push URL to SSH, using the 1Password SSH agent
[group('Repo management WITH GitHub authentication')]
dev-configure-remote-for-https-fetch-and-ssh-push:
    git -C "{{genomac_local_dir}}" remote set-url origin "{{genomac_fetch_url}}"
    git -C "{{genomac_local_dir}}" remote set-url --push origin "{{genomac_push_url}}"
    git -C "{{genomac_local_dir}}" config pull.rebase false

############### System state utilities

[group('State utilities')]
system-states command:
    zsh scripts/utilities/system_state_utilities.sh '{{command}}'

[group('State utilities')]
system-states-show:
    just system-states show

[group('State utilities')]
system-states-clear-session-states:
    just system-states clear-session

[group('State utilities')]
system-states-clear-all-states:
    just system-states clear-all

############### Logging utilities

[group('Log file utilities')]
logging command:
    zsh scripts/utilities/logging_utilities.sh '{{command}}'

[group('Log file utilities')]
logging-show-latest:
    just logging show-latest

[group('Log file utilities')]
logging-show-directory:
    just logging show-directory

############### Spawn-related commands

[group('User-spawning utilities')]
spawn-related command:
    zsh scripts/spawn/spawn-related-commands.sh '{{command}}'

[group('User-spawning utilities')]
spawn-related-test-parent-of-home-directories-from-volume:
	just spawn-related test-home-directories-parent

[group('User-spawning utilities')]
spawn-related-does-user-exist:
	just spawn-related test-user-exists

[group('User-spawning utilities')]
spawn-related-what-is-startup-container:
	just spawn-related what-is-startup-container

[group('User-spawning utilities')]
spawn-related-ensure-volume-exists:
	just spawn-related ensure-volume-exists

[group('User-spawning utilities')]
spawn-related-create-user:
	just spawn-related add-user
