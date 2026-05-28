#!/usr/bin/env zsh

function subdermis() {

  report_start_phase_standard

  # Source required files
  safe_source "${GMS_HOMEBREW_INSTALL_SCRIPTS}/adjust_path_for_homebrew.sh"
  safe_source "${GMS_HOMEBREW_INSTALL_SCRIPTS}/install_via_homebrew.sh"
  safe_source "${GMS_HOMEBREW_INSTALL_SCRIPTS}/interactive_sign_into_MAS.sh"
  safe_source "${GMS_INSTALL_SCRIPTS}/helpers_for_installations.sh"
  safe_source "${GMS_INSTALL_SCRIPTS}/helpers_for_gh_readiness.sh"
  safe_source "${GMS_INSTALL_SCRIPTS}/install_rosetta.sh"
  safe_source "${GMS_NON_HOMEBREW_INSTALL_SCRIPTS}/install_non_homebrew_apps.sh"
  safe_source "${GMS_RESOURCE_INSTALL_SCRIPTS}/install_resources.sh"
  safe_source "${GMS_SETTINGS_SCRIPTS}/implement_systemwide_settings.sh"
  safe_source "${GMS_SETTINGS_SCRIPTS}/interactive_get_Mac_names_and_login_window_message.sh"
  safe_source "${GMS_USER_SCOPE_SCRIPTS}/clone_genomac_user_repo.sh"
  safe_source "${GMS_USER_SPAWNING_SCRIPTS}/spawn.sh"

  # TODO:
  # - Consider adding environment variable SESH_FORCED_LOGOUT_DIRTY to avoid
  #   gratuitous logouts. An action requiring --forced-logout would (a) set this
  #   state rather than immediately triggering a logout.
  #   Requires new function `hypervisor_forced_logout_if_dirty`

  output_hypervisor_welcome_banner "$GENOMAC_SCOPE_SYSTEM"
  keep_sudo_alive
  set_genomac_system_state "$SESH_SESSION_HAS_STARTED"

  # Mark the configuring user as a USER_CONFIGURER
  # Only USER_CONFIGURER runs GenoMac-system, therefore this user is USER_CONFIGURER
  # Use the *user*-state management system to leave a state for this user that will
  # tell GenoMac-user to configure this user as a USER_CONFIGURER user.
  # NOTE: TODO: This doesn’t seem to be used by GenoMac-user
  set_genomac_user_state   "$PERM_THIS_USER_IS_A_USER_CONFIGGER"
  
  interactive_ensure_terminal_has_fda             # GenoMac-shared/scripts/helpers-misc.sh
  conditionally_adjust_path_for_homebrew          # scripts/installations/homebrew/adjust_path_for_homebrew.sh
  conditionally_interactive_get_Mac_names_and_login_window_message # scripts/settings/interactive_get_Mac_names_and_login_window_message.sh
  conditionally_interactive_sign_into_MAS         # scripts/installations/homebrew/interactive_sign_into_MAS.sh
  conditionally_install_rosetta                   # scripts/installations/install_rosetta.sh
  conditionally_install_via_homebrew              # scripts/installations/homebrew/install_via_homebrew.sh
  conditionally_install_non_homebrew_apps         # scripts/installations/non_homebrew/install_non_homebrew_apps.sh
  conditionally_install_resources_systemwide      # scripts/installations/of_resources/install_resources.sh
  conditionally_implement_systemwide_settings     # scripts/settings/implement_systemwide_settings.sh
  conditionally_clone_genomac_user_using_HTTPS    # scripts/user_scope/clone_genomac_user_repo.sh
  conditionally_create_user_accounts_for_this_Mac # scripts/spawn/spawn.sh

  # TODO
  # Report volumes that are pending creation, and walk through to create them
  # Report to USER_CONFIGURER the list of user/volume combos that are in need of initial configuration
  
  report_end_phase_standard
}

