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
  safe_source "${GMS_RESOURCE_INSTALL_SCRIPTS}/make_development_clones.sh"
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
  mark_current_user_as_user_configger                      # GenoMac-shared/scripts/helpers-state-xfer-btw-system-user.sh
  
  interactive_ensure_terminal_has_fda                      # GenoMac-shared/scripts/helpers-misc.sh
  conditionally_adjust_path_for_homebrew                   # scripts/installations/homebrew/adjust_path_for_homebrew.sh
  conditionally_interactive_get_Mac_names_and_login_window_message # scripts/settings/interactive_get_Mac_names_and_login_window_message.sh
  conditionally_interactive_sign_into_MAS                  # scripts/installations/homebrew/interactive_sign_into_MAS.sh
  conditionally_install_rosetta                            # scripts/installations/install_rosetta.sh
  conditionally_install_via_homebrew                       # scripts/installations/homebrew/install_via_homebrew.sh
  conditionally_install_non_homebrew_apps                  # scripts/installations/non_homebrew/install_non_homebrew_apps.sh
  conditionally_install_resources_systemwide               # scripts/installations/of_resources/install_resources.sh
  conditionally_implement_systemwide_settings              # scripts/settings/implement_systemwide_settings.sh

  # Default attributes for USER_CONFIGURER must be set before USER_CONFIGURER uses GenoMac-user to configure
  # USER_CONFIGURER’s user-scoped settings. Therefore we do it before GenoMac-user is even locally cloned
  # in order to enforce this condition.
  conditionally_set_default_attributes_for_USER_CONFIGURER # scripts/spawn/default_attributes_for_user_configurer.sh

  # Clone GenoMac-user to ~/.genomac-user in preparation for USER_CONFIGURER to configure its own account
  conditionally_clone_genomac_user_using_HTTPS             # scripts/user_scope/clone_genomac_user_repo.sh
  
  conditionally_create_user_accounts_for_this_Mac          # scripts/spawn/spawn.sh
  conditionally_interactive_create_volumes_for_user_home_directories    # scripts/spawn/spawn-volume-creation.sh
  display_users_to_be_initially_configured                 # GenoMac-shared/scripts/helpers-state-xfer-btw-system-user.sh
  
  report_end_phase_standard
}

