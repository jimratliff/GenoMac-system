# Makefile for GenoMac project

# --------------------------------------------------------------------
# Phony targets (not real files)
# --------------------------------------------------------------------
.PHONY: \
    app-install-via-homebrew \
    clone-genomac-user \
	font-install \
    prefs-systemwide \
    provision-volumes-and-users \
	resources-install \
	screensaver-install \
	sound-install \
    test_user_creation \
    test_volume_creation \

# --------------------------------------------------------------------
# Targets
# --------------------------------------------------------------------

run-hypervisor:
	zsh scripts/run_hypervisor.sh

refresh-repo:
	git -C ~/.genomac-system pull --recurse-submodules origin main

## Updates genomac-system repo, including genomac-shared submodule, and pushes it back to GitHub
## git diff… checks whether there are staged changes to the submodule and, if so, commits them

dev-update-repo-and-submodule:
	cd ~/.genomac-system
	git pull --recurse-submodules origin main
	git submodule update --remote
	git add external/genomac-shared
	git diff --cached --quiet external/genomac-shared || git commit -m "Update genomac-shared submodule"
	git push origin main

# Configure remote for HTTPS fetch and SSH push
# Sets the fetch URL to HTTPS (no auth needed for public repo)
# Sets the push URL to SSH (uses 1Password SSH agent)
dev-configure-remote-for-https-fetch-and-ssh-push:
	cd ~/.genomac-system
	git remote set-url origin https://github.com/jimratliff/GenoMac-system.git
	git remote set-url --push origin git@github.com:jimratliff/GenoMac-system.git

############### UTILITIES


show-system-states:
	zsh scripts/utilities/show_system_states.sh

clear-system-sesh-states:
	zsh scripts/utilities/clear_system_sesh_states.sh

clear-all-system-states:
	zsh scripts/utilities/clear_all_system_states.sh



############### 38th Parallel

app-install-via-homebrew:
	zsh scripts/install_via_homebrew.sh

adjust-path:
	zsh scripts/adjust_path_for_homebrew.sh

app-install-other-than-homebrew:
	zsh scripts/install_non_homebrew_apps.sh

resources-install:
	zsh scripts/install_resources.sh

font-install:
	zsh scripts/install_fonts.sh

screensaver-install:
	zsh scripts/install_screensavers.sh

sound-install:
	zsh scripts/install_sounds.sh

prefs-systemwide:
	zsh scripts/implement_systemwide_prefs.sh

clone-genomac-user:
	zsh scripts/clone_genomac_user_repo.sh
	
provision-volumes-and-users:
	zsh scripts/provision_vols_and_users.sh

test_user_creation:
	@zsh scripts/test_scripts/test_user_creation.sh

test_volume_creation:
	@zsh scripts/test_scripts/test_volume_creation.sh
