#!/bin/zsh

# Installs, upgrades, and (when necessary) removes no-longer-desired Homebrew packages.

# Fail early on unset variables or command failure
set -euo pipefail

# Resolve this script's directory (even if sourced)
this_script_path="${0:A}"
this_script_dir="${this_script_path:h}"

# Ensure Homebrew is in PATH for this script
# Should be unnecessary, so I'm commenting it out
eval "$(/opt/homebrew/bin/brew shellenv)"

# Assign environment variables (including GENOMAC_HELPER_DIR).
# Assumes that assign_environment_variables.sh is in same directory as this script.
source "${this_script_dir}/assign_environment_variables.sh"

# Source helpers
source "${GENOMAC_HELPER_DIR}/helpers.sh"

############################## BEGIN SCRIPT PROPER ##############################
function install_via_homebrew() {
  report_start_phase_standard

  # For nonobvious reasons, brew install requires a password to install some casks
  # Preemptively calling `keep_sudo_alive` doesn’t prevent this

  # Says: don’t quarantine installed apps
  # This duplicates the effect of `HOMEBREW_CASK_OPTS=--no-quarantine` in `.config/homebrew/brew.env`
  # but this dotfile hasn’t been established by the time this script runs the first time when 
  # bootstrapping a Mac.
  report_action_taken "Suppressing quarantine flag on to-be-installed apps"
  export HOMEBREW_CASK_OPTS=--no-quarantine

  # Assumes Brewfile is in homebrew/, which is parallel to scripts/
  brewfile_path="${this_script_dir}/../homebrew/Brewfile"

  # Updates Homebrew itself and its package definitions (formulae and casks) from the remote repository
  report_action_taken "Updating Homebrew itself"
  brew update; success_or_not

  # Installs packages, etc. from Brewfile
  # --cleanup removes installed packages no longer called for by the Brewfile
  report_action_taken "Install new packages and remove no-longer-desired ones"
  report_warning "Don’t walk away! You’ll be required to enter your password for some apps."
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

function post_homebrew_installs_initialization() {
  report_start_phase_standard

  # The glance-chamburr app must be launched once in order to set up its QuickLook plugin
  launch_and_quit "com.chamburr.Glance"
}

function main() {
  # Installs apps, etc. via Homebrew and runs post-Homebrew initializations.
  #
  # For idiosyncratic reasons, one or more apps may fail to install/update, but Homebrew keeps chugging along,
  # trying to install subsequent apps.
  #
  # Therefore, I still want to run the post-Homebrew initializations even if install_via_homebrew returns a
  # nonzero error code.
  #
  # But nevertheless, I want main() to return a nonzero error code if either of these two functions returns
  # a nonzero error code.

  local rc_install=0 rc_post=0

  install_via_homebrew || {
    rc_install=$?
    report_fail "⚠️ install_via_homebrew failed with $rc_install; continuing"
  }

  post_homebrew_installs_initialization || {
    rc_post=$?
    report_fail "⚠️ post_homebrew_installs_initialization failed with $rc_post"
  }

  (( rc_install || rc_post )) && return 1
}

main
