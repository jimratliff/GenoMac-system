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

# Export environment variables to be available in all subsequent shells
# TODO: Revisit below commented-out line after refactoring (to use GenoMac-shared)
# report_action_taken "Exporting environment variables to be consistently available."
echo "Exporting environment variables to be consistently available."

# TODO: After refactoring is completed (viz., to reply on GenoMac-shared), this function definition can be deleted
# function export_and_report() {
#   local var_name="$1"
#   report "export $var_name: '${(P)var_name}'"
#   export "$var_name"
# }

export_and_report GENOMAC_HELPER_DIR
export_and_report GENOMAC_SYSTEM_LOCAL_DIRECTORY
export_and_report GENOMAC_SYSTEM_LOCAL_RESOURCE_DIRECTORY
export_and_report GENOMAC_USER_LOGIN_PICTURES_DIRECTORY
