#!/usr/bin/env zsh

function conditionally_set_default_attributes_for_USER_CONFIGURER() {
  # Conditionally sets default user attributes for USER_CONFIGURER as
  # system-scoped state files.
  #
  # These attributes will be read when USER_CONFIGURER using GenoMac-user
  # to configure USER_CONFIGURER’s user-scoped settings.
  #
  # This is a bootstrap step to address fact that USER_CONFIGURER is *not*
  # created by GenoMac-system’s Spawn process. (It is during this Spawn
  # process that, for all other users, a user’s attributes are written
  # as system-scoped state files.)
  
  report_start_phase_standard

  run_if_system_has_not_done \
    "$PERM_USER_CONFIGURER_DEFAULT_ATTRIBUTES_HAVE_BEEN_SET" \
    set_default_attributes_for_USER_CONFIGURER \
    "Skipping setting default attributes for USER_CONFIGURER, because these were set in the past."
    
  report_end_phase_standard
}

function set_default_attributes_for_USER_CONFIGURER() {
  # Sets a system-scoped state encoded with (a) user name and (b) user-attribute name
  # for the currently executing user (referred to as USER_CONFIGURER).
  
  report_start_phase_standard
  local attribute
  local short_name

  # USER_CONFIGURER is the user running GenoMac-system
  short_name="$(short_name_of_user_from_HOME)"

  for attribute in "${GENOMAC_STATE_USER_CONFIGURER_DEFAULT_ATTRIBUTES[@]}"; do
    set_system_state_for_user_attribute "$short_name" "$attribute"
  done
  
  report_end_phase_standard
}
