#!/bin/zsh

# Establishes values for certain environment variables to ensure compatibility across scripts.
#
# This script is assumed to reside in the same directory as the helpers.sh script of helper functions.
#
# This script is applicable to at least the GenoMac and GenoMac-bootstrap repositories. It may also be
# applicable to the GenoMac-dotfiles repository.
# Thus, ultimately this script, along with helpers.sh, might be relocated into a git submodule.

set -euo pipefail

# Resolve directory of the current script
# Explanation
#	•	(%):-%N:                 Path of the current script, even when sourced.
#	  •	%N                     The filename of the current script.
#	  •	(%):-%N                Forces expansion in sourced/non-interactive contexts.
#	•	${this_script_path:A}:   Resolves the path to an absolute path (:A is the absolute path modifier).
#	•	${this_script_path:A:h}: Appends :h to get the directory (i.e., “head” — the part before the final slash).
# WARNING: The above comment is no longer applicable, because I no longer use %N
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

source "${GENOMAC_HELPER_DIR}/helpers.sh"

# Specify URL to clone GenoMac repository
GENOMAC_REPO_URL="git@github.com:jimratliff/GenoMac.git"

# Specify URL to clone public GenoMac-dotfiles repository using HTTPS
GENOMAC_DOTFILES_REPO_URL="https://github.com/jimratliff/GenoMac-dotfiles.git"

# Specify local directory into which the GenoMac-bootstrap repository will be cloned
# Note:
# - This repo is cloned only for USER_CONFIGURER.
# - This local clone will be deleted after it is used to clone the GenoMac repo.
GENOMAC_BOOTSTRAP_LOCAL_DIRECTORY="$HOME/bootstrap"

# Specify local directory into which the GenoMac repository will be cloned
# Note: This repo is cloned only for USER_CONFIGURER.
GENOMAC_LOCAL_DIRECTORY="$HOME/genomac"

# Specify local directory into which the GenoMac-dotfiles repository will be cloned.
# I.e., this is the “stow directory” for the dotfiles.
# Note:
# - This directory will be cloned into EACH USER’s home directory
# - This cloning into other users’ home directories will be performed 
#   by USER_CONFIGURER using the login-style `su - user_b` to act (a) as each other user and 
#   (b) under that other user’s environment.
#   This is required in order that it is the *other user’s* home directory that is the one modified.
GENOMAC_DOTFILES_LOCAL_STOW_DIRECTORY="$HOME/.genomac-dotfiles"

# Export environment variables to be available in all subsequent shells
report_action_taken "Exporting environment variables to be consistently available."

function export_and_report() {
  local var_name="$1"
  report "export $var_name: '${(P)var_name}'"
  export "$var_name";success_or_not
}

export_and_report GENOMAC_HELPER_DIR
export_and_report GENOMAC_REPO_URL
export_and_report GENOMAC_DOTFILES_REPO_URL
export_and_report GENOMAC_BOOTSTRAP_LOCAL_DIRECTORY
export_and_report GENOMAC_LOCAL_DIRECTORY
export_and_report GENOMAC_DOTFILES_LOCAL_STOW_DIRECTORY




