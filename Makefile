# Makefile for GenoMac project

GENOMAC_SYSTEM_DIR := $(HOME)/.genomac-system

# --------------------------------------------------------------------
# Phony targets (not real files)
# --------------------------------------------------------------------
.PHONY: \
	run-hypervisor \
	refresh-repo \
	dev-update-repo-and-submodule \
	dev-configure-remote-for-https-fetch-and-ssh-push

# --------------------------------------------------------------------
# Targets
# --------------------------------------------------------------------

run-hypervisor:
	zsh scripts/run_hypervisor.sh

refresh-repo:
	git -C "$(GENOMAC_SYSTEM_DIR)" pull --recurse-submodules origin main

## Updates genomac-system repo, including genomac-shared submodule, and pushes it back to GitHub
## git diff… checks whether there are staged changes to the submodule and, if so, commits them
dev-update-repo-and-submodule:
	git -C "$(GENOMAC_SYSTEM_DIR)" pull --recurse-submodules origin main
	git -C "$(GENOMAC_SYSTEM_DIR)" submodule update --remote
	git -C "$(GENOMAC_SYSTEM_DIR)" add external/genomac-shared
	git -C "$(GENOMAC_SYSTEM_DIR)" diff --cached --quiet external/genomac-shared || git -C "$(GENOMAC_SYSTEM_DIR)" commit -m "Update genomac-shared submodule"
	git -C "$(GENOMAC_SYSTEM_DIR)" push origin main

# Configure remote for HTTPS fetch and SSH push
# Sets the fetch URL to HTTPS (no auth needed for public repo)
# Sets the push URL to SSH (uses 1Password SSH agent)
dev-configure-remote-for-https-fetch-and-ssh-push:
	git -C "$(GENOMAC_SYSTEM_DIR)" remote set-url origin https://github.com/jimratliff/GenoMac-system.git
	git -C "$(GENOMAC_SYSTEM_DIR)" remote set-url --push origin git@github.com:jimratliff/GenoMac-system.git
