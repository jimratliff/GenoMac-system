# Makefile for GenoMac project

# --------------------------------------------------------------------
# Phony targets (not real files)
# --------------------------------------------------------------------
.PHONY: \
    app-install-via-homebrew \
	font-install \
	screensaver-install \
	resources-install \
    prefs-systemwide \
    clone-genomac-user \
    provision-volumes-and-users \
    test_user_creation \
    test_volume_creation

# --------------------------------------------------------------------
# Targets
# --------------------------------------------------------------------

app-install-via-homebrew:
	zsh scripts/install_via_homebrew.sh

font-install:
	zsh scripts/install_fonts.sh

resources-install:
	zsh scripts/install_resources.sh

screensaver-install:
	zsh scripts/install_screensavers.sh

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
