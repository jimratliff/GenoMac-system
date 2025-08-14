#!/bin/zsh

# Installs, upgrades, and (when necessary) removes no-longer-desired Homebrew packages.

# Fail early on unset variables or command failure
set -euo pipefail

# Resolve this script's directory (even if sourced)
this_script_path="${0:A}"
this_script_dir="${this_script_path:h}"

# Assign environment variables (including GENOMAC_HELPER_DIR).
# Assumes that assign_environment_variables.sh is in same directory as this script.
source "${this_script_dir}/assign_environment_variables.sh"

# Source helpers
source "${GENOMAC_HELPER_DIR}/helpers.sh"

############################## BEGIN SCRIPT PROPER ##############################
function install_via_homebrew() {
  report_start_phase_standard

  # Assumes Brewfile is in homebrew/, which is parallel to scripts/
  brewfile_path="${this_script_dir}/../homebrew/Brewfile"

  # Updates Homebrew itself and its package definitions (formulae and casks) from the remote repository
  report_action_taken "Updating Homebrew itself"
  brew update; success_or_not

  # Installs packages, etc. from Brewfile
  # --cleanup removes installed packages no longer called for by the Brewfile
  report_action_taken "Install new packages and remove no-longer-desired ones"
  brew bundle install --cleanup --file="${brewfile_path}"; success_or_not

  # Upgrades, as necessary, installed packages
  report_action_taken "Upgrades, as needed, installed packages"
  brew upgrade; success_or_not

  # Removes stale lock files and outdated downloads for all formulae and casks, and removes old versions of installed formulae.
  # Removes all downloads more than 120 days old. 
  report_action_taken "Cleans up Homebrew installations"
  brew cleanup; success_or_not

  report_end_phase_standard

}

function main() {
  install_via_homebrew
}

main
