#!/usr/bin/env zsh

# Establishes values for certain environment variables to ensure compatibility 
# across scripts.
#
# This script is assumed to reside in the same directory as the helpers.sh 
# script of helper functions.
#
# This script is applicable to at least the GenoMac-system and GenoMac-user 
# repositories. Because this script is used in multiple repos, ultimately this 
# script, along with helpers.sh, might be relocated into a git submodule.

set -euo pipefail

# Resolve directory of the current script
this_script_path="${0:A}"
this_script_dir="${this_script_path:h}"

# Specify the directory in which the `helpers.sh` file lives.
# E.g., when `helpers.sh` lives at the same level as this script:
# GENOMAC_HELPER_DIR="${this_script_dir}"
GENOMAC_HELPER_DIR="${this_script_dir}"

# Print assigned paths for diagnostic purposes
printf "\n📂 Path diagnostics:\n"
printf "this_script_dir:                  %s\n" "$this_script_dir"
printf "GENOMAC_HELPER_DIR:               %s\n" "$GENOMAC_HELPER_DIR"

# Source the helpers script
source "${GENOMAC_HELPER_DIR}/helpers.sh"

# Specify the local directory in which user login pictures are stored to be
# accessed during user-account creation.
GENOMAC_USER_LOGIN_PICTURES_DIRECTORY="$HOME/.genomac-user-login-pictures"

# Specify local directory into which the GenoMac-system repository will be 
# cloned
# Note: This repo is cloned only by USER_CONFIGURER.
GENOMAC_SYSTEM_LOCAL_DIRECTORY="$HOME/.genomac-system"



# Export environment variables to be available in all subsequent shells
report_action_taken "Exporting environment variables to be consistently available."

function export_and_report() {
  local var_name="$1"
  report "export $var_name: '${(P)var_name}'"
  export "$var_name"
}

export_and_report GENOMAC_HELPER_DIR
export_and_report GENOMAC_SYSTEM_LOCAL_DIRECTORY
export_and_report GENOMAC_USER_LOGIN_PICTURES_DIRECTORY
