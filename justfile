# For syntax/behavior of just, see https://github.com/casey/just

# use `just --choose` to be presented with an interactive chooser to select the particular recipe

# Typing only 'just' will run this default recipe, displaying interactive chooser.
default:
	@just --choose

############### Run the Hypervisor

run-hypervisor:
    zsh scripts/run_hypervisor.sh

############### Repo management

refresh-repo:
    git -C ~/.genomac-system pull --recurse-submodules origin main

# Updates genomac-system repo, including genomac-shared submodule, and pushes it back to GitHub.
# The git diff check detects whether there are staged changes to the submodule and, if so, commits them.
[working-directory: "~/.genomac-system"]
dev-update-repo-and-submodule:
    git pull --recurse-submodules origin main
    git submodule update --remote
    git add external/genomac-shared
    git diff --cached --quiet external/genomac-shared || git commit -m "Update genomac-shared submodule"
    git push origin main

[working-directory: "~/.genomac-system"]
dev-configure-remote-for-https-fetch-and-ssh-push:
    git remote set-url origin https://github.com/jimratliff/GenoMac-system.git
    git remote set-url --push origin git@github.com:jimratliff/GenoMac-system.git


############### System state utilities

system-states command:
    zsh scripts/utilities/system_state_utilities.zsh {{command}}

show-system-states:
    just system-states show

clear-system-sesh-states:
    just system-states clear-seshion

clear-all-system-states:
    just system-states clear-all
