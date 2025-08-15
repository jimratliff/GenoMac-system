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

# Specify URL for cloning the public GenoMac-system repository using HTTPS
GENOMAC_SYSTEM_REPO_URL="https://github.com/jimratliff/GenoMac-system.git"

# Specify URL for cloning the public GenoMac-user repository using HTTPS
GENOMAC_USER_REPO_URL="https://github.comjimratliff/GenoMac-user.git"

# Specify local directory into which the GenoMac-system repository will be 
# cloned
# Note: This repo is cloned only by USER_CONFIGURER.
GENOMAC_SYSTEM_LOCAL_DIRECTORY="$HOME/.genomac-system"

# Specify local directory into which the GenoMac-user repository will be cloned
# Note: This repo is cloned by each user.
GENOMAC_USER_LOCAL_DIRECTORY="$HOME/.genomac-user"

# Specify the local directory that is the “stow directory” that GNU Stow uses as
# both (a) the raw dotfiles representing various configurations and (b) the
# structural template defining where each symlink should reside in the user’s
# $HOME directory.
GENOMAC_USER_LOCAL_STOW_DIRECTORY="$GENOMAC_USER_LOCAL_DIRECTORY/stow_directory"

# Export environment variables to be available in all subsequent shells
report_action_taken "Exporting environment variables to be consistently available."

function export_and_report() {
  local var_name="$1"
  report "export $var_name: '${(P)var_name}'"
  export "$var_name";success_or_not
}

export_and_report GENOMAC_HELPER_DIR
export_and_report GENOMAC_SYSTEM_REPO_URL
export_and_report GENOMAC_USER_REPO_URL
export_and_report GENOMAC_SYSTEM_LOCAL_DIRECTORY
export_and_report GENOMAC_USER_LOCAL_DIRECTORY
export_and_report GENOMAC_USER_LOCAL_STOW_DIRECTORY




