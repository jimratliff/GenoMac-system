#!/usr/bin/env zs

# Fail early on unset variables or command failure
set -euo pipefail

source "${HOME}/.genomac-system/scripts/0_initialize_me.sh"

############### TODO WIP! Being refactored from GenoMac-user to GenoMac-system

# Source required files
safe_source "${GMS_PREFS_SCRIPTS}/interactive_ask_initial_questions.sh" # INCORRECT, for example only
safe_source "${GMS_PREFS_SCRIPTS}/get_full_disk_access_for_terminals.sh"

############### Context
# It is assumed that, prior to running this script:
# - Homebrew has been installed
#   - This process also installs Xcode Developer Tools, which itself installs git
# - The GenoMac-system repo has been cloned to ~/.genomac-system directory within USER_CONFIGURER’s
#   home directory.
#
# This script can then be executed by launching Terminal and then typing:
#   cd ~/.genomac-system
#   make run-hypervisor

function run_hypervisor() {

  report_start_phase_standard

  # TODO:
  # - Consider checking $set_genomac_system_state "$SESH_REACHED_FINALITY" to
  #   check whether this is an immediate reentry after a complete session and,
  #   if so, to ask whether the user wants to start a new session.
  # - Consider adding environment variable SESH_FORCED_LOGOUT_DIRTY to avoid
  #   gratuitous logouts. An action requiring --forced-logout would (a) set this
  #   state rather than immediately triggering a logout.
  #   Requires new function `hypervisor_forced_logout_if_dirty`

  ############### Welcome! or Welcome back!
  local welcome_message="Welcome"
  if test_genomac_system_state "$SESH_SESSION_HAS_STARTED"; then
    welcome_message="Welcome back"
  else
    set_genomac_system_state "$SESH_SESSION_HAS_STARTED"
  fi
  
  report "${welcome_message} to the GenoMac-system Hypervisor!"
  report "$GMU_HYPERVISOR_HOW_TO_RESTART_STRING"

  ############### Test for Full Disk Access for the currently running terminal application
  interactive_ensure_terminal_has_fda

  # Guard clause: Fail fast if Homebrew not installed
  ensure_homebrew_is_installed

  ############### Adjust PATH for Homebrew
  conditionally_adjust_path_for_homebrew

  ############### Prompt user to sign into Mac App Store
  conditionally_interactive_sign_into_MAS

  ############### Install apps via Homebrew
  conditionally_install_via_homebrew

  
  ############### PERM: Ask initial questions
  run_if_system_has_not_done \
    "$PERM_INTRO_QUESTIONS_ASKED_AND_ANSWERED" \
    interactive_ask_initial_questions \
    "Skipping introductory questions, because you've answered them in the past."
  
  ############### SESH: Stow dotfiles
  run_if_system_has_not_done \
    --force-logout \
    "$SESH_DOTFILES_HAVE_BEEN_STOWED" \
    stow_dotfiles \
    "Skipping stowing dotfiles, because you've already stowed them during this session."

  ############### SESH: Configure primary programmatically implemented settings
  run_if_system_has_not_done \
    --force-logout \
    "$SESH_BASIC_IDEMPOTENT_SETTINGS_HAVE_BEEN_IMPLEMENTED" \
    perform_basic_system_level_settings \
    "Skipping basic system-level settings, because they’ve already been set this session"


  


  ############### Last act: Delete all SESH_ state environment variables

  # delete_all_system_SESH_states

  set_genomac_system_state "$SESH_REACHED_FINALITY"
  
  # TODO: Un-comment-out the below 'figlet' line after GenoMac-system is refactored so that it works
  # figlet "The End"
  
  # hypervisor_force_logout
  
  report_end_phase_standard
}

function main() {
  run_hypervisor
}

main
