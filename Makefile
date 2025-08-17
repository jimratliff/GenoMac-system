# Makefile for GenoMac project

# --------------------------------------------------------------------
# Phony targets (not real files)
# --------------------------------------------------------------------
.PHONY: \
    install-via-homebrew \
    system-wide-prefs \
    clone-genomac-user \
    provision-volumes-and-users \
    test_user_creation \
    test_volume_creation

# --------------------------------------------------------------------
# Targets
# --------------------------------------------------------------------

install-via-homebrew:
	zsh scripts/install_via_homebrew.sh

system-wide-prefs:
	zsh scripts/implement_systemwide_prefs.sh

clone-genomac-user:
	zsh scripts/clone_genomac_user_repo.sh
	
provision-volumes-and-users:
	zsh scripts/provision_vols_and_users.sh

test_user_creation:
	@zsh scripts/test_scripts/test_user_creation.sh

test_volume_creation:
	@zsh scripts/test_scripts/test_volume_creation.sh
