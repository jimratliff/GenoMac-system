#!/usr/bin/env zs

function install_via_homebrew() {
  # Installs, upgrades, and (when necessary) removes no-longer-desired Homebrew packages.
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
  brewfile_path="${GMU_SCRIPTS_DIR:h}/homebrew/Brewfile"

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

  install_via_homebrew
  dump_accumulated_warnings_failures
}

main
