#!/usr/bin/env zsh

function get_1Password_key_from_delimited_state_string(){
  # Get the 1Password item key from a delimited volume-1Pkey state string
  # See _construct_state_string_for_volume_1password_key() for background
  report_start_phase_standard
  local state_string="$1"
  local op_key

  op_key="${state_string##*${GENOMAC_STATE_STRING_DELIMITER_B}}"

  print -- "$op_key"
  
  report_end_phase_standard
}
