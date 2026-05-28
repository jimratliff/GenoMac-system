#!/usr/bin/env zsh

function conditionally_interactive_create_volumes_for_user_home_directories(){
  # Template for a Zsh function in Project GenoMac
  report_start_phase_standard

  local -a pending_volume_state_strings
  collect_state_strings_for_volumes_pending_creation
  pending_volume_state_strings=("${reply[@]}")

  if (( ! ${#pending_volume_state_strings[@]} )); then
    report "There are no volumes pending creation. Moving on…"
    report_end_phase_standard
    return 0
  fi

  
  
  report_end_phase_standard
}

function collect_state_strings_for_volumes_pending_creation(){
  # Sets reply to an array of state strings of system-scoped states that assert
  # that a volume name is pending creation.

  report_start_phase_standard
  local pattern
  local -a matching_state_paths
  
  pattern="${GMS_STATE_VOLUME_IS_PENDING_PREFIX}${GENOMAC_STATE_STRING_DELIMITER_A}"
  matching_state_paths=("${GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY}"/"${pattern}"*."${GENOMAC_STATE_FILE_EXTENSION}"(N:t:r))
  reply=("${matching_state_paths[@]}")
  
  report_end_phase_standard
}
