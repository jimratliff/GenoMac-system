#!/usr/bin/env zsh

# Source environment variables corresponding to enums for states
source_with_report "${GMS_HYPERVISOR_SCRIPTS}/assign_enum_env_vars_for_states.sh"

function subdermis() {

  report_start_phase_standard

  # Source required files
  safe_source "${GMS_HOMEBREW_INSTALL_SCRIPTS}/install_via_homebrew.sh"
  safe_source "${GMS_HOMEBREW_INSTALL_SCRIPTS}/interactive_sign_into_MAS.sh"
  safe_source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_non_homebrew_apps.sh"
  safe_source "${GMS_RESOURCE_INSTALL_SCRIPTS}/install_resources.sh"
  safe_source "${GMS_SETTINGS_SCRIPTS}/adjust_path_for_homebrew.sh"
  safe_source "${GMS_SETTINGS_SCRIPTS}/implement_systemwide_settings.sh"
  safe_source "${GMS_SETTINGS_SCRIPTS}/interactive_get_Mac_names_and_login_window_message.sh"
  safe_source "${GMS_USER_SCOPE_SCRIPTS}/clone_genomac_user_repo.sh"

  GMS_HYPERVISOR_MAKE_COMMAND_STRING="make run-hypervisor"
  local hypervisor_make_message="To restart, re-execute ${GMS_HYPERVISOR_MAKE_COMMAND_STRING} and we’ll pick up where we left off."
  GMS_HYPERVISOR_HOW_TO_RESTART_STRING="${hypervisor_make_message}"

  # TODO:
  # - Consider checking $set_genomac_system_state "$SESH_REACHED_FINALITY" to
  #   check whether this is an immediate reentry after a complete session and,
  #   if so, to ask whether the user wants to start a new session.
  # - Consider adding environment variable SESH_FORCED_LOGOUT_DIRTY to avoid
  #   gratuitous logouts. An action requiring --forced-logout would (a) set this
  #   state rather than immediately triggering a logout.
  #   Requires new function `hypervisor_forced_logout_if_dirty`

  ############### Welcome! or Welcome back!
  local welcome_message
  if test_genomac_system_state "$SESH_SESSION_HAS_STARTED"; then
    welcome_message="Welcome back"
  else
    welcome_message="Welcome"
    set_genomac_system_state "$SESH_SESSION_HAS_STARTED"
  fi
  
  report "${welcome_message} to the GenoMac-system Hypervisor!"
  report "$GMS_HYPERVISOR_HOW_TO_RESTART_STRING"


  interactive_ensure_terminal_has_fda         # GenoMac-shared/scripts/helpers-interactive.sh
  crash_if_homebrew_not_installed             # GenoMac-shared/scripts/helpers-apps.sh
  conditionally_adjust_path_for_homebrew      # scripts/installations/homebrew/adjust_path_for_homebrew.sh
  conditionally_interactive_get_Mac_names_and_login_window_message # scripts/settings/interactive_get_Mac_names_and_login_window_message.sh
  conditionally_interactive_sign_into_MAS     # scripts/installations/homebrew/interactive_sign_into_MAS.sh
  conditionally_install_via_homebrew          # scripts/installations/homebrew/install_via_homebrew.sh
  conditionally_install_non_homebrew_apps     # scripts/installations/non_homebrew/install_non_homebrew_apps.sh
  conditionally_install_resources_systemwide  # scripts/installations/of_resources/install_resources.sh
  conditionally_implement_systemwide_settings # scripts/settings/implement_systemwide_settings.sh
  # conditionally_clone_genomac_user            # scripts/user_scope/clone_genomac_user_repo.sh

  
  # TODO: Un-comment-out the below 'figlet' line after GenoMac-system is refactored so that it works
  # figlet "The End"
  
  # hypervisor_force_logout
  
  report_end_phase_standard
}
