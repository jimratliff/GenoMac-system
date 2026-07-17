#!/usr/bin/env zsh

function conditionally_set_user_pictures_for_vanilla_and_configurer() {
  # Set user picture for each of USER_VANILLA and USER_CONFIGURER, if not done before.
  report_start_phase_standard

  run_if_system_has_not_done \
    "$PERM_USER_CONFIGURER_USER_PICTURE_HAS_BEEN_SET" \
    set_user_picture_for_user_configurer \
    "Skipping setting user picture for USER_CONFIGURER, because this was done in the past."

  run_if_system_has_not_done \
    "$PERM_USER_VANILLA_USER_PICTURE_HAS_BEEN_SET" \
    set_user_picture_for_user_vanilla \
    "Skipping setting user picture for USER_VANILLA, because this was done in the past."
    
  report_end_phase_standard
}

function set_user_picture_for_user_configurer() {
  # Assign to USER_CONFIGURER the default user picture for that user
  report_start_phase_standard
  local path_to_user_picture
  local short_name_for_user_configurer
  
  short_name_for_user_configurer="$USER"
  path_to_user_picture="$GMS_DEFAULT_USER_PICTURE_FOR_USER_CONFIGURER"
  
  set_user_picture "$short_name_for_user_configurer" "$path_to_user_picture"   # scripts/spawn/spawn-helpers.sh
  report_end_phase_standard
}

function set_user_picture_for_user_vanilla() {
  # Assign to USER_VANILLA the default user picture for that user
  report_start_phase_standard
  local path_to_user_picture
  local short_name_for_user_vanilla
  
  short_name_for_user_vanilla="$SHORT_NAME_OF_USER_VANILLA"
  path_to_user_picture="$GMS_DEFAULT_USER_PICTURE_FOR_USER_VANILLA"
  
  # Ensure USER_VANILLA actually exists as a user
  if ! does_user_name_exist "$short_name_for_user_vanilla"; then
    report_fail "USER_VANILLA (“$short_name_for_user_vanilla”) doesn’t exist as a user."
    return 1
  fi
  
  set_user_picture "$short_name_for_user_vanilla" "$path_to_user_picture"   # scripts/spawn/spawn-helpers.sh
  report_end_phase_standard
}
