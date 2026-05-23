#!/usr/bin/env zsh

function _construct_state_string_for_volume_1password_key(){
  # Constructs a state string of the form 'VOLUME_CREATION_IS_COMPLETE_∞§¶some_volume¶§∞PERSONAL_PASSWORD'
  # where:
  #   'VOLUME_CREATION_IS_COMPLETE_' could instead be 'VOLUME_CREATION_IS_PENDING_'
  #   'some_volume' is the name of a volume
  #   'PERSONAL_PASSWORD' is a 1Password item key
  #
  # - $3 is expected to be either GMS_STATE_VOLUME_IS_CREATED_PREFIX or GMS_STATE_VOLUME_IS_PENDING_PREFIX
  # - The first delimiter (between the the state_string_prefix and the volume name) is GENOMAC_STATE_STRING_DELIMITER_A
  #   - GENOMAC_STATE_STRING_DELIMITER_A="∞§¶"
  # - The second delimiter (between the volume name and the 1Password item key) is GENOMAC_STATE_STRING_DELIMITER_B
  #   - GENOMAC_STATE_STRING_DELIMITER_B="¶§∞"
  report_start_phase_standard
  local volume_name="$1"
  local op_item_key="$2"
  local state_string_prefix="$3"
  local state_string

  state_string="${state_string_prefix}${GENOMAC_STATE_STRING_DELIMITER_A}${volume_name}${GENOMAC_STATE_STRING_DELIMITER_B}${op_item_key}"
  print -- "$state_string"
  
  report_end_phase_standard
}

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
