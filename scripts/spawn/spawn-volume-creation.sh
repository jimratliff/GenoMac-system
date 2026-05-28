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

  construct_map_from_volume_key_to_open_item_key_from_pending_creation_state_strings


  report_end_phase_standard
}

function construct_map_from_volume_key_to_open_item_key_from_pending_creation_state_strings(){
  # Returns associative array from array of volumes-pending-creation state strings, where
  # the associative array maps volume_name to op_item_key.
  #
  # If multiple state strings share a common volume_name, generate fatal error.
  
  report_start_phase_standard
  local pending_volume_state_strings
  pending_volume_state_strings="$1"

  local -A op_item_key_from_volume_name
  local state_string
  local volume_name
  local op_item_key
  local error_string

  for state_string in "${pending_volume_state_strings[@]}"; do
    volume_name=$(volume_name_from_pending_volume_state_string "$state_string")
    op_item_key=$(op_item_key_from_pending_volume_state_string "$state_string")

    if [[ -v 'op_item_key_from_volume_name[$volume_name]' ]]; then
      report_fail "Multiple pending-creation states for volume ${volume_name}"
      return 1
    fi

    op_item_key_from_volume_name[$volume_name]="$op_item_key"
  done
  reply=("${op_item_key_from_volume_name[@]}")
  
  report_end_phase_standard
}
