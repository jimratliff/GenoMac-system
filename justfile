# For syntax/behavior of just, see https://github.com/casey/just

# use `just --choose` to be presented with an interactive chooser to select the particular recipe

# Typing only 'just' will run this default recipe, displaying interactive chooser.
default:
	@just --choose

############### Run the Hypervisor

run-hypervisor:
    zsh scripts/run_hypervisor.sh

############### Repo management

genomac_system_dir := env_var('HOME') / '.genomac-system'

refresh-repo:
    git -C "{{genomac_system_dir}}" pull --recurse-submodules origin main

# Updates genomac-system repo, including genomac-shared submodule, and pushes it back to GitHub.
# The git diff check detects whether there are staged changes to the submodule and, if so, commits them.
dev-update-repo-and-submodule:
    git -C "{{genomac_system_dir}}" pull --recurse-submodules origin main
    git -C "{{genomac_system_dir}}" submodule update --remote
    git -C "{{genomac_system_dir}}" add external/genomac-shared
    git -C "{{genomac_system_dir}}" diff --cached --quiet external/genomac-shared || git -C "{{genomac_system_dir}}" commit -m "Update genomac-shared submodule"
    git -C "{{genomac_system_dir}}" push origin main

dev-configure-remote-for-https-fetch-and-ssh-push:
    git -C "{{genomac_system_dir}}" remote set-url origin https://github.com/jimratliff/GenoMac-system.git
    git -C "{{genomac_system_dir}}" remote set-url --push origin git@github.com:jimratliff/GenoMac-system.git


############### System state utilities

system-states command:
    zsh scripts/utilities/system_state_utilities.sh '{{command}}'

show-system-states:
    just system-states show

clear-system-session-states:
    just system-states clear-session

clear-all-system-states:
    just system-states clear-all
