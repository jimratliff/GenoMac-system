#!/usr/bin/env zsh

# Establishes values for environment variables used exclusively by GenoMac-system

set -euo pipefail

# Specify the local directory in which user login pictures are stored to be
# accessed during user-account creation.
# QUERY: IS THIS CORRECT? DO THESE RESIDE IN CONFIGGER’S HOME DIRECTORY?
GENOMAC_USER_LOGIN_PICTURES_DIRECTORY="$HOME/.genomac-user-login-pictures"

# Specify local directory into which the GenoMac-system repository will be 
# cloned
# Note: This repo is cloned only by USER_CONFIGURER.
GENOMAC_SYSTEM_LOCAL_DIRECTORY="$HOME/.genomac-system"

# Specify the local directory that holds resources (files or folders) needed for particular
# operations by GenoMac-system
GENOMAC_SYSTEM_LOCAL_RESOURCE_DIRECTORY="${GENOMAC_SYSTEM_LOCAL_DIRECTORY}/resources"

# Specify the local directory that holds documentation files to display to the executing user
GENOMAC_SYSTEM_DOCS_TO_DISPLAY_DIRECTORY="${GENOMAC_USER_LOCAL_RESOURCE_DIRECTORY}/docs_to_display_to_user"

# Specify the local directory that holds declarative Homebrew files
GENOMAC_SYSTEM_LOCAL_HOMEBREW_DIRECTORY="${GENOMAC_SYSTEM_LOCAL_DIRECTORY}/homebrew"

# Environment variables to support the Hypervisor
GMS_HYPERVISOR_MAKE_COMMAND_STRING="make run-hypervisor"
GMS_HYPERVISOR_HOW_TO_RESTART_STRING="To get back into the groove at any time, just re-execute ${GMS_HYPERVISOR_MAKE_COMMAND_STRING}${NEWLINE}and we’ll pick up where we left off."

report_action_taken "Export environment variables to be available in all subsequent shells."

export_and_report GENOMAC_SYSTEM_LOCAL_DIRECTORY
export_and_report GENOMAC_SYSTEM_LOCAL_DOCUMENTATION_DIRECTORY
export_and_report GENOMAC_SYSTEM_LOCAL_HOMEBREW_DIRECTORY
export_and_report GENOMAC_SYSTEM_LOCAL_RESOURCE_DIRECTORY
export_and_report GENOMAC_USER_LOGIN_PICTURES_DIRECTORY
