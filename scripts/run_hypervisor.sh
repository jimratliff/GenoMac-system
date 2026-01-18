#!/usr/bin/env zs

# Fail early on unset variables or command failure
set -euo pipefail

source "${HOME}/.genomac-system/scripts/0_initialize_me.sh"

############### WIP! Being refactored from GenoMac-user to GenoMac-system

# Source required files
safe_source "${GMU_PREFS_SCRIPTS}/interactive_ask_initial_questions.sh"
safe_source "${GMU_PREFS_SCRIPTS}/interactive_configure_1password.sh"
safe_source "${GMU_PREFS_SCRIPTS}/interactive_configure_alfred.sh"
safe_source "${GMU_PREFS_SCRIPTS}/interactive_configure_dropbox.sh"
safe_source "${GMU_PREFS_SCRIPTS}/interactive_configure_keyboard_maestro.sh"
safe_source "${GMU_PREFS_SCRIPTS}/interactive_configure_textexpander.sh"
safe_source "${GMU_PREFS_SCRIPTS}/perform_basic_user_level_settings.sh"
safe_source "${GMU_PREFS_SCRIPTS}/perform_initial_bootstrap_operations.sh"
safe_source "${GMU_PREFS_SCRIPTS}/perform_stow_dotfiles.sh"

function run_hypervisor() {

  report_start_phase_standard

  # TODO:
  # - Consider checking $set_genomac_user_state "$SESH_REACHED_FINALITY" to
  #   check whether this is an immediate reentry after a complete session and,
  #   if so, to ask whether the user wants to start a new session.
  # - Consider adding environment variable SESH_FORCED_LOGOUT_DIRTY to avoid
  #   gratuitous logouts. An action requiring --forced-logout would (a) set this
  #   state rather than immediately triggering a logout.
  #   Requires new function `hypervisor_forced_logout_if_dirty`

  ############### Welcome! or Welcome back!
  local welcome_message="Welcome"
  if test_genomac_user_state "$SESH_SESSION_HAS_STARTED"; then
    welcome_message="Welcome back"
  else
    set_genomac_user_state "$SESH_SESSION_HAS_STARTED"
  fi
  
  report "${welcome_message} to the GenoMac-user Hypervisor!"
  report "$GMU_HYPERVISOR_HOW_TO_RESTART_STRING"
  
  ############### PERM: Ask initial questions
  run_if_user_has_not_done \
    "$PERM_INTRO_QUESTIONS_ASKED_AND_ANSWERED" \
    interactive_ask_initial_questions \
    "Skipping introductory questions, because you've answered them in the past."
  
  ############### SESH: Stow dotfiles
  run_if_user_has_not_done \
    --force-logout \
    "$SESH_DOTFILES_HAVE_BEEN_STOWED" \
    stow_dotfiles \
    "Skipping stowing dotfiles, because you've already stowed them during this session."

  ############### SESH: Configure primary programmatically implemented settings
  run_if_user_has_not_done \
    --force-logout \
    "$SESH_BASIC_IDEMPOTENT_SETTINGS_HAVE_BEEN_IMPLEMENTED" \
    perform_basic_user_level_settings \
    "Skipping basic user-level settings, because they’ve already been set this session"

  ############### SESH: Modify Desktop for certain users
  if test_genomac_user_state "$PERM_FINDER_SHOW_DRIVES_ON_DESKTOP"; then
    run_if_user_has_not_done \
      "$SESH_FINDER_SHOW_DRIVES_ON_DESKTOP_HAS_BEEN_IMPLEMENTED" \
      reverse_disk_display_policy_for_some_users \
      "Skipping displaying internal/external drives on Desktop, because I’ve already done so this session"
  else
    report_action_taken "Skipping displaying internal/external drives on Desktop, because this user doesn’t want it"
  fi
  
  ############### PERM: Execute pre-Dropbox bootstrap steps
  run_if_user_has_not_done \
    --force-logout \
    "$PERM_BASIC_BOOTSTRAP_OPERATIONS_HAVE_BEEN_PERFORMED" \
    perform_initial_bootstrap_operations \
    "Skipping basic bootstrap operations, because they’ve already been performed"

  ############### Conditionally configure 1Password
  # 1Password is configured at this point in order to be available when subsequent
  # apps need to be signed into
  conditionally_configure_1Password

  ############### PERM: Conditionally configure TextExpander
  conditionally_configure_textexpander

  ############### PERM: Conditionally configure Dropbox
  conditionally_configure_Dropbox

  ############### PERM: (Further) configure apps that rely upon Dropbox
  if test_genomac_user_state "$PERM_DROPBOX_HAS_BEEN_CONFIGURED"; then
    conditionally_configure_keyboard_maestro

    # Alfred must be configured *after* Keyboard Maestro, because activating the
    #   Powerpack uses a custom Keyboard Maestro macro
    conditionally_configure_alfred
  fi

  ############### Execute post–Dropbox sync operations

  ############### Configure Microsoft Word
  # conditionally_configure_microsoft_word

  ############### Last act: Delete all SESH_ state environment variables

  # delete_all_user_SESH_states

  set_genomac_user_state "$SESH_REACHED_FINALITY"
  
  # TODO: Un-comment-out the below 'figlet' line after GenoMac-system is refactored so that it works
  # figlet "The End"
  
  # hypervisor_force_logout
  
  report_end_phase_standard
}

function main() {
  run_hypervisor
}

main
