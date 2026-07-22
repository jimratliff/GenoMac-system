# Makefile for the GenoMac project
#
# This Makefile exists only for a limited bootstrap purpose. The first
# time GenoMac-system is used on a Mac, `just` is not yet available.
# Until the bootstrap process installs `just`, these operations can be
# run with `make`.

.DEFAULT_GOAL := help

# Directory containing this Makefile, including its trailing slash.
makefile_dir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# --------------------------------------------------------------------
# Phony targets (not real files)
# --------------------------------------------------------------------
.PHONY: \
	help \
	refresh-repo-and-submodule \
	run-hypervisor

help:
	@printf '%s\n' \
		'Available targets:' \
		'  refresh-repo-and-submodule' \
		'  run-hypervisor'

# Refresh local checkout from origin/main, including submodules.
# Does not require GitHub authentication.
# WARNING: discards local commits and tracked-file changes in this
# managed checkout. It does not remove untracked files.
refresh-repo-and-submodule:
	git -C "$(HOME)/.genomac-system" fetch origin main
	git -C "$(HOME)/.genomac-system" reset --hard origin/main
	git -C "$(HOME)/.genomac-system" submodule update --init --recursive

# Run from the project directory so the script's relative paths behave
# consistently even if Make was invoked from elsewhere.
run-hypervisor:
	cd "$(makefile_dir)" && zsh scripts/run_hypervisor.sh
