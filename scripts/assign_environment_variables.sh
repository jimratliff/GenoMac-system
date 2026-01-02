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

############### CONJECTURE: The following is used only by GenoMac-system

# Specify URL for cloning the public GenoMac-system repository using HTTPS
GENOMAC_SYSTEM_REPO_URL="https://github.com/jimratliff/GenoMac-system.git"

# Specify local directory into which the GenoMac-system repository will be 
# cloned
# Note: This repo is cloned only by USER_CONFIGURER.
GENOMAC_SYSTEM_LOCAL_DIRECTORY="$HOME/.genomac-system"

############### CONJECTURE: The following is used only by GenoMac-user

# Specify the location of the user’s `Dropbox` directory
GENOMAC_USER_DROPBOX_DIRECTORY="$HOME/Library/CloudStorage/Dropbox"

# Specify the local directory in which preferences and other files shared across users are stored
# These may contain secrets, so this directory is NOT within a repo
# E.g., this would be within each user’s Dropbox directory.
GENOMAC_USER_SHARED_PREFERENCES_DIRECTORY="${GENOMAC_USER_DROPBOX_DIRECTORY}/Preferences_common"

# Specify the file name of the BetterTouchTool (BTT) preset to be auto-loaded at BTT startup
GENOMAC_USER_BTT_AUTOLOAD_PRESET_FILENAME="Default_preset.json"
GENOMAC_USER_BTT_AUTOLOAD_PRESET_DIRECTORY="$HOME/.config/BetterTouchTool"
GENOMAC_USER_BTT_AUTOLOAD_PRESET_PATH="${GENOMAC_USER_BTT_AUTOLOAD_PRESET_DIRECTORY}/${GENOMAC_USER_BTT_AUTOLOAD_PRESET_FILENAME}"

# Export environment variables to be available in all subsequent shells
report_action_taken "Exporting environment variables to be consistently available."

function export_and_report() {
  local var_name="$1"
  report "export $var_name: '${(P)var_name}'"
  export "$var_name"
}


export_and_report GENOMAC_ALERT_LOG
export_and_report GENOMAC_HELPER_DIR
export_and_report GENOMAC_NAMESPACE
export_and_report GENOMAC_STATE_FILE_EXTENSION
export_and_report GENOMAC_SYSTEM_LOCAL_DIRECTORY
export_and_report GENOMAC_SYSTEM_REPO_URL
export_and_report GENOMAC_USER_DROPBOX_DIRECTORY
export_and_report GENOMAC_USER_LOCAL_DIRECTORY
export_and_report GENOMAC_USER_LOCAL_RESOURCE_DIRECTORY
export_and_report GENOMAC_USER_LOCAL_STATE_DIRECTORY
export_and_report GENOMAC_USER_LOGIN_PICTURES_DIRECTORY
export_and_report GENOMAC_USER_REPO_URL
export_and_report GENOMAC_USER_SHARED_PREFERENCES_DIRECTORY

