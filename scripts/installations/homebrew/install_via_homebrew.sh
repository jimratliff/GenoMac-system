#!/usr/bin/env zsh

function conditionally_install_via_homebrew() {
  report_start_phase_standard

  run_if_system_has_not_done \
    "$SESH_HOMEBREW_APPS_HAVE_BEEN_INSTALLED" \
    install_via_homebrew \
    "Skipping installation of apps via Homebrew, because this installation was performed earlier this session."

  report_end_phase_standard
}

function install_via_homebrew() {
  # Installs, upgrades, and removes no-longer-desired Homebrew packages.
  #
  # For nonobvious reasons, brew install requires a password to install some casks
  # Preemptively calling `keep_sudo_alive` doesn’t prevent this
  report_start_phase_standard

  # Says: don’t quarantine installed apps
  # This duplicates the effect of `HOMEBREW_CASK_OPTS=--no-quarantine` in `.config/homebrew/brew.env`
  # but this dotfile hasn’t been established by the time this script runs the first time when 
  # bootstrapping a Mac.
  report_action_taken "Suppressing quarantine flag on to-be-installed apps"
  export HOMEBREW_CASK_OPTS=--no-quarantine

  local brewfile_path
  brewfile_path="${GMS_HOMEBREW}/Brewfile"

  # Updates Homebrew itself and its package definitions (formulae and casks) from the remote repository
  report_action_taken "Updating Homebrew itself and package definitions"
  brew update ; success_or_not

  # Remove installed Homebrew items that are not declared in the aggregate Brewfile.
  # This is the replacement for the old `brew bundle install --cleanup`.
  report_action_taken "Removing Homebrew items not declared in Brewfile"
  brew bundle cleanup --file="${brewfile_path}" --force ; success_or_not

  # Installs packages, etc. from Brewfile
  report_action_taken "Install and upgrading Homebrew items declared in Brewfile (and its children)"
  report_warning "Don’t walk away! You’ll be required to enter your administrator password for some apps."
  brew bundle install --file="${brewfile_path}" ; success_or_not

  # Reconcile again after install. This catches anything made removable by dependency changes.
  report_action_taken "Removing Homebrew items not declared in Brewfile after install"
  brew bundle cleanup --file="${brewfile_path}" --force ; success_or_not

  # Removes stale lock files, outdated downloads, and old versions/caches
  report_action_taken "Cleans up Homebrew caches and old versions"
  brew cleanup ; success_or_not

  # Sets state to indicate that Homebrew has been used at least once to install apps
  # This ensures basic existence of non-builtin apps on which other parts of GenoMac-system relies
  set_genomac_system_state "$PERM_HOMEBREW_HAS_INSTALLED_APPS_AT_LEAST_ONCE"

  report_end_phase_standard

}
