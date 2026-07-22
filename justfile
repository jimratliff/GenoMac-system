# For syntax/behavior of just, see https://github.com/casey/just
#
# Use `just --list` to see list of recipes by group.
#
# Run bare `just` to open the interactive chooser to select the particular recipe.
# Recipes initially appear in justfile order, with the first public argument-free
# recipe at the bottom of the chooser.

# Set default shell for just to Zsh
set shell := ["zsh", "-c"]

# Prevent intra-recipe comments from being echoed to the terminal
set ignore-comments

# Typing only `just` displays the interactive chooser.
[default, private]
choose:
    @FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} --no-sort" just --unsorted --choose

############### Repo-specific configuration
# This section exists to enable closer reuse of justfile code between GenoMac-system and GenoMac-user.
# The recipes below this section refer to the variables defined immediately below. The definition
# of these variables are repo-specific.
# This allows the repo-specificity to be largely restricted to this section of variable definitions.

genomac_local_dir := env_var('HOME') / '.genomac-system'
genomac_remote_repo := 'GenoMac-system'
genomac_github_owner := 'jimratliff'

genomac_fetch_url := 'https://github.com/' + genomac_github_owner + '/' + genomac_remote_repo + '.git'
genomac_push_url := 'git@github.com:' + genomac_github_owner + '/' + genomac_remote_repo + '.git'

############### HIGH-PRIORITY RECIPES ###############
# The following will be listed in order (upward from the bottom in the fzf TUI’s left column)

# Refresh local checkout from origin/main, including submodules
[group('Repo management WITHOUT GitHub authentication')]
repo-refresh-repo-and-submodule:
    # Makes the superproject and all submodules match origin/main.
    # Does not require GitHub authentication.
    # Local modifications and extraneous files are intentionally discarded.
    git -C "{{genomac_local_dir}}" fetch origin main
    git -C "{{genomac_local_dir}}" reset --hard origin/main
    git -C "{{genomac_local_dir}}" submodule sync --recursive
    git -C "{{genomac_local_dir}}" submodule update --init --recursive --checkout --force
    git -C "{{genomac_local_dir}}" submodule foreach --recursive 'git reset --hard && git clean -ffdx'
    git -C "{{genomac_local_dir}}" clean -ffdx

# Run the Hypervisor-System
[group('Hypervisor')]
hypervisor-run:
    zsh scripts/run_hypervisor.sh

# Update repo/submodule, push → GitHub
[group('Repo management WITH GitHub authentication')]
dev-update-repo-main-branch-and-submodule:
    @branch="$(git -C {{quote(genomac_local_dir)}} branch --show-current)"; \
        if [[ "$branch" != main ]]; then \
            [[ -n "$branch" ]] || branch="detached HEAD"; \
            print -u2 -- "error: this recipe requires the main branch; current state: $branch"; \
            exit 1; \
        fi
    git -C "{{genomac_local_dir}}" pull --recurse-submodules origin main
    git -C "{{genomac_local_dir}}" submodule update --remote
    git -C "{{genomac_local_dir}}" add external/genomac-shared
    git -C "{{genomac_local_dir}}" diff --cached --quiet external/genomac-shared || git -C "{{genomac_local_dir}}" commit -m "Update genomac-shared submodule"
    git -C "{{genomac_local_dir}}" push origin main

############### Logging utilities

[group('Log file utilities')]
logging command:
    zsh scripts/utilities/logging_utilities.sh {{quote(command)}}

# Show latest GenoMac-system log file
[group('Log file utilities')]
logging-show-latest:
    just logging show-latest

# Show directory holding GenoMac-system log files
[group('Log file utilities')]
logging-show-directory:
    just logging show-directory

############### Remaining repository-management utility

# Configure remote for HTTPS fetch and SSH push 
[group('Repo management WITH GitHub authentication')]
dev-configure-remote-for-https-fetch-and-ssh-push:
    # Sets the fetch URL to HTTPS
    # Sets the push URL to SSH, using the 1Password SSH agent
    git -C "{{genomac_local_dir}}" remote set-url origin "{{genomac_fetch_url}}"
    git -C "{{genomac_local_dir}}" remote set-url --push origin "{{genomac_push_url}}"
    git -C "{{genomac_local_dir}}" config pull.rebase false

############### System state utilities

[group('State utilities')]
system-states command:
    zsh scripts/utilities/system_state_utilities.sh {{quote(command)}}

# Show directory containing state files
[group('State utilities')]
system-states-show:
    just system-states show

# Clear SESH state files
[group('State utilities')]
system-states-clear-session-states:
    just system-states clear-session

# DEPRECATED BELOW COMMAND because too easy/dangerous to trigger accidentally
# given there’s no real use case for it.
# [group('State utilities')]
# system-states-clear-all-states:
#    just system-states clear-all

############### Spawn-related commands

[group('User-spawning utilities')]
spawn-related command:
    zsh scripts/spawn/spawn-related-commands.sh {{quote(command)}}

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
