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

# --- Homebrew: hard dependency ------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  # First attempt failed - try adding Homebrew to PATH and retry
  if [ -x /opt/homebrew/bin/brew ]; then
    # Homebrew exists but isn't in PATH - fix temporarily
    eval "$(/opt/homebrew/bin/brew shellenv)"
    if ! command -v brew >/dev/null 2>&1; then
      echo "❌ Homebrew installation appears corrupted. Aborting."
      exit 1
    fi
  else
    echo "❌ Homebrew is required but not installed. Aborting."
    exit 1
  fi
fi

# Resolve once (don’t recompute if already set by the environment)
HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(/usr/bin/env brew --prefix)}"

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

# Specify location of PlistBuddy
PLISTBUDDY_PATH='/usr/libexec/PlistBuddy'

# Establish symbolic names for modifier keys
SHIFT_CHAR=$'\u21e7'     # ⇧
CONTROL_CHAR=$'\u2303'   # ⌃  
OPTION_CHAR=$'\u2325'    # ⌥
COMMAND_CHAR=$'\u2318'   # ⌘
META_MODIFIER_CHARS="${CONTROL_CHAR}${OPTION_CHAR}${COMMAND_CHAR}"
MODIFIERS_KEYBOARD_NAVIGATION="${SHIFT_CHAR}${OPTION_CHAR}${COMMAND_CHAR}"

# Specify URL for cloning the public GenoMac-system repository using HTTPS
GENOMAC_SYSTEM_REPO_URL="https://github.com/jimratliff/GenoMac-system.git"

# Specify URL for cloning the public GenoMac-user repository using HTTPS
GENOMAC_USER_REPO_URL="https://github.com/jimratliff/GenoMac-user.git"

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

# Specify the local directory into which the diff results of defaults_detective
# investigations will be saved.
GENOMAC_USER_LOCAL_DEFAULTS_DETECTIVE_RESULTS="$HOME/genomac-detective"

# Specify the local directory in which user login pictures are stored to be
# accessed during user-account creation.
GENOMAC_USER_LOGIN_PICTURES_DIRECTORY="$HOME/.genomac-user-login-pictures"

# Specify the local directory in which preferences and other files shared across users are stored
# These may contain secrets, so this directory is NOT within a repo
# E.g., this would be within each user’s Dropbox directory.
GENOMAC_USER_SHARED_PREFERENCES_DIRECTORY="$HOME/Dropbox/Share_prefs"

# Export environment variables to be available in all subsequent shells
echo "Exporting environment variables to be consistently available."

function export_and_report() {
  local var_name="$1"
  report "export $var_name: '${(P)var_name}'"
  export "$var_name"
}

export_and_report PLISTBUDDY_PATH
export_and_report SHIFT_CHAR
export_and_report CONTROL_CHAR
export_and_report OPTION_CHAR
export_and_report COMMAND_CHAR
export_and_report META_MODIFIER_CHARS
export_and_report MODIFIERS_KEYBOARD_NAVIGATION
export_and_report HOMEBREW_PREFIX
export_and_report GENOMAC_HELPER_DIR
export_and_report GENOMAC_SYSTEM_REPO_URL
export_and_report GENOMAC_USER_REPO_URL
export_and_report GENOMAC_SYSTEM_LOCAL_DIRECTORY
export_and_report GENOMAC_USER_LOCAL_DIRECTORY
export_and_report GENOMAC_USER_LOCAL_STOW_DIRECTORY
export_and_report GENOMAC_USER_LOCAL_DEFAULTS_DETECTIVE_RESULTS
export_and_report GENOMAC_USER_LOGIN_PICTURES_DIRECTORY
export_and_report GENOMAC_USER_SHARED_PREFERENCES_DIRECTORY
