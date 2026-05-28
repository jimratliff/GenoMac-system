#!/usr/bin/env zsh

function conditionally_interactive_create_volumes_for_user_home_directories(){
  # Template for a Zsh function in Project GenoMac
  report_start_phase_standard

  local -a pending_volume_state_strings
  collect_state_strings_for_volumes_pending_creation
  pending_volume_state_strings=("${reply[@]}")

  local number_of_pending_volumes
  number_of_pending_volumes=${#pending_volume_state_strings[@]}

  if (( ! $number_of_pending_volumes )); then
    report "There are no volumes pending creation. Moving on…"
    report_end_phase_standard
    return 0
  fi
  print report "There is/are $number_of_pending_volumes volume(s) pending creation."


  report_end_phase_standard
}


