#!/usr/bin/env zsh

# Source environment variables corresponding to enums for states
source_with_report "${GMS_HYPERVISOR_SCRIPTS}/assign_enum_env_vars_for_states.sh"

function subdermis() {

  report_start_phase_standard

  # Source required files
  safe_source "${GMS_HOMEBREW_INSTALL_SCRIPTS}/adjust_path_for_homebrew.sh"
  safe_source "${GMS_HOMEBREW_INSTALL_SCRIPTS}/install_via_homebrew.sh"
  safe_source "${GMS_HOMEBREW_INSTALL_SCRIPTS}/interactive_sign_into_MAS.sh"
  safe_source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_non_homebrew_apps.sh"
  safe_source "${GMS_RESOURCE_INSTALL_SCRIPTS}/install_resources.sh"
  safe_source "${GMS_SETTINGS_SCRIPTS}/implement_systemwide_settings.sh"
  safe_source "${GMS_SETTINGS_SCRIPTS}/interactive_get_Mac_names_and_login_window_message.sh"
  safe_source "${GMS_USER_SCOPE_SCRIPTS}/clone_genomac_user_repo.sh"

  # TODO:
  # - Consider adding environment variable SESH_FORCED_LOGOUT_DIRTY to avoid
  #   gratuitous logouts. An action requiring --forced-logout would (a) set this
  #   state rather than immediately triggering a logout.
  #   Requires new function `hypervisor_forced_logout_if_dirty`

  output_welcome_banner
  keep_sudo_alive
  set_genomac_system_state "$SESH_SESSION_HAS_STARTED"

  # Mark the configuring user as a USER_CONFIGURER
  # Only USER_CONFIGURER runs GenoMac-system, therefore this user is USER_CONFIGURER
  # Use the *user*-state management system to leave a state for this user that will
  # tell GenoMac-user to configure this user as a USER_CONFIGURER user.
  set_genomac_user_state   "$PERM_THIS_USER_IS_A_USER_CONFIGGER"
  
  interactive_ensure_terminal_has_fda          # GenoMac-shared/scripts/helpers-interactive.sh
  crash_if_homebrew_not_installed              # GenoMac-shared/scripts/helpers-apps.sh
  conditionally_adjust_path_for_homebrew       # scripts/installations/homebrew/adjust_path_for_homebrew.sh
  conditionally_interactive_get_Mac_names_and_login_window_message # scripts/settings/interactive_get_Mac_names_and_login_window_message.sh
  conditionally_interactive_sign_into_MAS      # scripts/installations/homebrew/interactive_sign_into_MAS.sh
  conditionally_install_via_homebrew           # scripts/installations/homebrew/install_via_homebrew.sh
  conditionally_install_non_homebrew_apps      # scripts/installations/non_homebrew/install_non_homebrew_apps.sh
  conditionally_install_resources_systemwide   # scripts/installations/of_resources/install_resources.sh
  conditionally_implement_systemwide_settings  # scripts/settings/implement_systemwide_settings.sh
  conditionally_clone_genomac_user_using_HTTPS # scripts/user_scope/clone_genomac_user_repo.sh

  output_departure_banner
  
  hypervisor_force_logout
  
  report_end_phase_standard
}

function output_welcome_banner() {
  local welcome_prefix
  if test_genomac_system_state "$SESH_SESSION_HAS_STARTED"; then
    welcome_prefix="Welcome back"
  else
    welcome_prefix="Welcome"
  fi

  welcome_message="${welcome_prefix} to the GenoMac-system Hypervisor!"
  print_banner_text "${welcome_message}"
  report "$HYPERVISOR_HOW_TO_RESTART_STRING"
}

function output_departure_banner() {
  departure_message="TTFN!"
  print_banner_text "${departure_message}"
}
